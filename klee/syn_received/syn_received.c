#include "core/socket.h"
#include "klee/klee.h"
#include "core/tcp_misc.h"
#include <assert.h>
#include <stdlib.h>
#include "model.h"


void tcpStateEstablished(Socket *socket, TcpHeader *segment,
   const NetBuffer *buffer, size_t offset, size_t length)
{
   uint_t flags = 0;

   //Debug message
   // TRACE_DEBUG("TCP FSM: ESTABLISHED state\r\n");

   //First check sequence number
   if(tcpCheckSequenceNumber(socket, segment, length))
      return;

   //Check the RST bit
   if(segment->flags & TCP_FLAG_RST)
   {
      //Switch to the CLOSED state
      tcpChangeState(socket, TCP_STATE_CLOSED);

      //Number of times TCP connections have made a direct transition to the
      //CLOSED state from either the ESTABLISHED state or the CLOSE-WAIT state
      // MIB2_INC_COUNTER32(tcpGroup.tcpEstabResets, 1);
      // TCP_MIB_INC_COUNTER32(tcpEstabResets, 1);

      //Return immediately
      return;
   }

   //Check the SYN bit
   if(tcpCheckSyn(socket, segment, length))
      return;
   //Check the ACK field
   if(tcpCheckAck(socket, segment, length))
      return;
   //Process the segment text
   if(length > 0)
      tcpProcessSegmentData(socket, segment, buffer, offset, length);

   //Check the FIN bit
   if(segment->flags & TCP_FLAG_FIN)
   {
      //The FIN can only be acknowledged if all the segment data
      //has been successfully transferred to the receive buffer
      if(socket->rcvNxt == (segment->seqNum + length))
      {
         //Advance RCV.NXT over the FIN
         socket->rcvNxt++;
         //Send an acknowledgment for the FIN
         tcpSendSegment(socket, TCP_FLAG_ACK, socket->sndNxt, socket->rcvNxt, 0, FALSE);
         //Switch to the CLOSE-WAIT state
         tcpChangeState(socket, TCP_STATE_CLOSE_WAIT);
      }
   }

#if (TCP_CONGEST_CONTROL_SUPPORT == ENABLED)
   //Duplicate AK received?
   if(socket->dupAckCount > 0)
      flags = SOCKET_FLAG_NO_DELAY;
#endif

   //The Nagle algorithm should be implemented to coalesce
   //short segments (refer to RFC 1122 4.2.3.4)
   tcpNagleAlgo(socket, flags);
}

void tcpStateSynReceived(Socket *socket, TcpHeader *segment,
                         const NetBuffer *buffer, size_t offset, size_t length)
{
    //Debug message
    // TRACE_DEBUG("TCP FSM: SYN-RECEIVED state\r\n");

    //First check sequence number
    if (tcpCheckSequenceNumber(socket, segment, length))
        return;

    //Check the RST bit
    if (segment->flags & TCP_FLAG_RST)
    {
        //Return to CLOSED state
        tcpChangeState(socket, TCP_STATE_CLOSED);

        //Number of times TCP connections have made a direct transition to the
        //CLOSED state from either the SYN-SENT state or the SYN-RECEIVED state
        //MIB2_INC_COUNTER32(tcpGroup.tcpAttemptFails, 1);
        //TCP_MIB_INC_COUNTER32(tcpAttemptFails, 1);

        //Return immediately
        return;
    }

    //Check the SYN bit
    if (tcpCheckSyn(socket, segment, length))
        return;

    //If the ACK bit is off drop the segment and return
    if (!(segment->flags & TCP_FLAG_ACK))
        return;

    //Make sure the acknowledgment number is valid
    if (segment->ackNum != socket->sndNxt)
    {
        //If the segment acknowledgment is not acceptable, form a reset
        //segment and send it
        tcpSendSegment(socket, TCP_FLAG_RST, segment->ackNum, 0, 0, FALSE);

        //Drop the segment and return
        return;
    }

    //Update the send window before entering ESTABLISHED state (refer to
    //RFC 1122, section 4.2.2.20)
    socket->sndWnd = segment->window;
    socket->sndWl1 = segment->seqNum;
    socket->sndWl2 = segment->ackNum;

    //Maximum send window it has seen so far on the connection
    socket->maxSndWnd = segment->window;

    //Enter ESTABLISHED state
    tcpChangeState(socket, TCP_STATE_ESTABLISHED);
    //And continue processing...
    tcpStateEstablished(socket, segment, buffer, offset, length);
}

int main()
{
    // Initialisation
    socketInit();

    Socket *socket;
    IpPseudoHeader *pseudoHeader;
    TcpHeader *segment;
    size_t length;
    uint32_t ackNum, seqNum;
    uint8_t flags, dataOffset;
    uint16_t checksum, srcPort;
    struct socketModel *sModel;

    segment = malloc(sizeof(TcpHeader) + sizeof(u_int8_t));
    pseudoHeader = malloc(sizeof(IpPseudoHeader));

    // creation of a TCP socket
    socket = socketOpen(SOCKET_TYPE_STREAM, SOCKET_IP_PROTO_TCP);

    // TODO: See if it is the correct way to process.
    // Maybe open the connection by following the real call of the function
    // is a better way to do.
    tcpChangeState(socket, TCP_STATE_SYN_RECEIVED);

    // Creation of a "random" incomming package
    // We assume the pseudo header is filled with ipv4 addresses

    klee_make_symbolic(&ackNum, sizeof(ackNum), "ackNum");
    klee_make_symbolic(&seqNum, sizeof(seqNum), "seqNum");
    klee_make_symbolic(&flags, sizeof(flags), "flags");
    klee_assume(0 <= flags && flags <= 31);
    klee_make_symbolic(&checksum, sizeof(checksum), "checksum");
    klee_make_symbolic(&dataOffset, sizeof(dataOffset), "dataOffset");
    klee_assume(0 <= dataOffset && dataOffset <= 15);
    klee_make_symbolic(&srcPort, sizeof(srcPort), "srcPort");
    // The port cannot be null
    klee_assume(srcPort != 0);

    segment->srcPort = srcPort;
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

    klee_assert(socket->state == TCP_STATE_SYN_RECEIVED);

    tcpStateSynReceived(socket, segment, NULL, 0, 0);

    klee_assert(equalSocketModel(socket, sModel) &&
                (socket->state == TCP_STATE_SYN_RECEIVED ||
                 socket->state == TCP_STATE_ESTABLISHED ||
                 socket->state != TCP_STATE_CLOSE_WAIT ||
                 (socket->state == TCP_STATE_CLOSED &&
                  socket->resetFlag)));
}
