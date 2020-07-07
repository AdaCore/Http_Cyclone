#include "core/socket.h"
#include "klee/klee.h"
#include "core/tcp_misc.h"
#include <assert.h>
#include <stdlib.h>
#include "model.h"


void tcpStateSynSent(Socket *socket, TcpHeader *segment, size_t length)
{
   TcpOption *option;

   //Debug message
   // TRACE_DEBUG("TCP FSM: SYN-SENT state\r\n");

   //Check the ACK bit
   if(segment->flags & TCP_FLAG_ACK)
   {
      //Make sure the acknowledgment number is valid
      if(segment->ackNum != socket->sndNxt)
      {
         //Send a reset segment unless the RST bit is set
         if(!(segment->flags & TCP_FLAG_RST))
            tcpSendSegment(socket, TCP_FLAG_RST, segment->ackNum, 0, 0, FALSE);

         //Drop the segment and return
         return;
      }
   }

   //Check the RST bit
   if(segment->flags & TCP_FLAG_RST)
   {
      //Make sure the ACK is acceptable
      if(segment->flags & TCP_FLAG_ACK)
      {
         //Enter CLOSED state
         tcpChangeState(socket, TCP_STATE_CLOSED);

         //Number of times TCP connections have made a direct transition to the
         //CLOSED state from either the SYN-SENT state or the SYN-RECEIVED state
         // MIB2_INC_COUNTER32(tcpGroup.tcpAttemptFails, 1);
         // TCP_MIB_INC_COUNTER32(tcpAttemptFails, 1);
      }

      //Drop the segment and return
      return;
   }

   //Check the SYN bit
   if(segment->flags & TCP_FLAG_SYN)
   {
      //Save initial receive sequence number
      socket->irs = segment->seqNum;
      //Initialize RCV.NXT pointer
      socket->rcvNxt = segment->seqNum + 1;

      //If there is an ACK, SND.UNA should be advanced to equal SEG.ACK
      if(segment->flags & TCP_FLAG_ACK)
         socket->sndUna = segment->ackNum;

      //Compute retransmission timeout
      tcpComputeRto(socket);

      //Any segments on the retransmission queue which are thereby
      //acknowledged should be removed
      tcpUpdateRetransmitQueue(socket);

      //Get the maximum segment size
      option = tcpGetOption(segment, TCP_OPTION_MAX_SEGMENT_SIZE);

      //Specified option found?
      if(option != NULL && option->length == 4)
      {
         //Retrieve MSS value
         osMemcpy(&socket->smss, option->value, 2);
         //Convert from network byte order to host byte order
         socket->smss = ntohs(socket->smss);

         //Debug message
         // TRACE_DEBUG("Remote host MSS = %" PRIu16 "\r\n", socket->smss);

         //Make sure that the MSS advertised by the peer is acceptable
         socket->smss = MIN(socket->smss, TCP_MAX_MSS);
         socket->smss = MAX(socket->smss, TCP_MIN_MSS);
      }

#if (TCP_CONGEST_CONTROL_SUPPORT == ENABLED)
      //Initial congestion window
      socket->cwnd = MIN(TCP_INITIAL_WINDOW * socket->smss, socket->txBufferSize);
#endif

      //Check whether our SYN has been acknowledged (SND.UNA > ISS)
      if(TCP_CMP_SEQ(socket->sndUna, socket->iss) > 0)
      {
         //Update the send window before entering ESTABLISHED state (refer to
         //RFC 1122, section 4.2.2.20)
         socket->sndWnd = segment->window;
         socket->sndWl1 = segment->seqNum;
         socket->sndWl2 = segment->ackNum;

         //Maximum send window it has seen so far on the connection
         socket->maxSndWnd = segment->window;

         //Form an ACK segment and send it
         tcpSendSegment(socket, TCP_FLAG_ACK, socket->sndNxt, socket->rcvNxt, 0, FALSE);
         //Switch to the ESTABLISHED state
         tcpChangeState(socket, TCP_STATE_ESTABLISHED);
      }
      else
      {
         //Form an SYN ACK segment and send it
         tcpSendSegment(socket, TCP_FLAG_SYN | TCP_FLAG_ACK, socket->iss, socket->rcvNxt, 0, TRUE);
         //Enter SYN-RECEIVED state
         tcpChangeState(socket, TCP_STATE_SYN_RECEIVED);
      }
   }
}

int main()
{
    // Initialisation
    socketInit();

    Socket *socket;
    TcpHeader *segment;
    size_t length;
    uint32_t ackNum, seqNum;
    uint8_t flags, dataOffset;
    uint16_t checksum;
    struct socketModel *sModel;

    segment = malloc(sizeof(TcpHeader) + sizeof(u_int8_t));

    // creation of a TCP socket
    socket = socketOpen(SOCKET_TYPE_STREAM, SOCKET_IP_PROTO_TCP);

    // TODO: See if it is the correct way to process.
    // Maybe open the connection by following the real call of the function
    // is a better way to do.
    tcpChangeState(socket, TCP_STATE_SYN_SENT);

    klee_make_symbolic(&ackNum, sizeof(ackNum), "ackNum");
    klee_make_symbolic(&seqNum, sizeof(seqNum), "seqNum");
    klee_make_symbolic(&flags, sizeof(flags), "flags");
    klee_assume(0 <= flags && flags <= 31);
    klee_make_symbolic(&checksum, sizeof(checksum), "checksum");
    klee_make_symbolic(&dataOffset, sizeof(dataOffset), "dataOffset");
    klee_assume(0 <= dataOffset && dataOffset <= 15);

    segment->srcPort = 80;
    segment->destPort = socket->localPort;
    segment->seqNum = seqNum;
    segment->ackNum = ackNum;
    segment->reserved1 = 0;
    segment->dataOffset = dataOffset;
    segment->flags = flags;
    segment->reserved2 = 0;
    segment->window = 26883; // Voir ce que c'est exactement
    segment->checksum = checksum;
    segment->urgentPointer = 0;
    segment->options[0] = 0;

    klee_make_symbolic(&length, sizeof(length), "length");

    // We make a hard copy of the struct to check if the fields have
    // changed after the call to the function
    sModel = toSockModel(socket);

    klee_assert(socket->state == TCP_STATE_SYN_SENT);

    tcpStateSynSent(socket, segment, length);

    klee_assert(equalSocketModel(socket, sModel) &&
                (socket->state == TCP_STATE_SYN_SENT ||
                 socket->state == TCP_STATE_SYN_RECEIVED ||
                 socket->state == TCP_STATE_ESTABLISHED ||
                 (socket->state == TCP_STATE_CLOSED &&
                  socket->resetFlag)));

}
