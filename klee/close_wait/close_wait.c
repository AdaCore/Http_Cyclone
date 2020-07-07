#include "core/socket.h"
#include "klee/klee.h"
#include "core/tcp_misc.h"
#include <assert.h>
#include <stdlib.h>
#include "model.h"


void tcpStateCloseWait(Socket *socket, TcpHeader *segment, size_t length)
{
   uint_t flags = 0;

   //Debug message
   // TRACE_DEBUG("TCP FSM: CLOSE-WAIT state\r\n");

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
    //   MIB2_INC_COUNTER32(tcpGroup.tcpEstabResets, 1);
    //   TCP_MIB_INC_COUNTER32(tcpEstabResets, 1);

      //Return immediately
      return;
   }

   //Check the SYN bit
   if(tcpCheckSyn(socket, segment, length))
      return;
   //Check the ACK field
   if(tcpCheckAck(socket, segment, length))
      return;

#if (TCP_CONGEST_CONTROL_SUPPORT == ENABLED)
   //Duplicate AK received?
   if(socket->dupAckCount > 0)
      flags = SOCKET_FLAG_NO_DELAY;
#endif

   //The Nagle algorithm should be implemented to coalesce
   //short segments (refer to RFC 1122 4.2.3.4)
   tcpNagleAlgo(socket, flags);
}

int main() {
    // Initialisation
    socketInit();

    Socket* socket;
    TcpHeader *segment;
    size_t length;
    uint32_t ackNum, seqNum;
    uint8_t flags;
    uint16_t checksum;
    struct socketModel* sModel;

    segment = malloc(sizeof(TcpHeader));

    // creation of a TCP socket
    socket = socketOpen(SOCKET_TYPE_STREAM, SOCKET_IP_PROTO_TCP);

    // TODO: See if it is the correct way to process.
    // Maybe open the connection by following the real call of the function
    // is a better way to do.
    tcpChangeState(socket, TCP_STATE_CLOSE_WAIT);

    klee_assert(socket->state == TCP_STATE_CLOSE_WAIT);

    klee_make_symbolic(&ackNum, sizeof(ackNum), "ackNum");
    klee_make_symbolic(&seqNum, sizeof(seqNum), "seqNum");
    klee_make_symbolic(&flags, sizeof(flags), "flags");
    klee_assume(flags >= 0 && flags <= 31);
    klee_make_symbolic(&checksum, sizeof(checksum), "checksum");

    segment->srcPort = 80;
    segment->destPort = socket->localPort;
    segment->seqNum = seqNum;
    segment->ackNum = ackNum;
    segment->reserved1 = 0;
    segment->dataOffset = 6; // Normalement sans importance
    segment->flags = flags;
    segment->reserved2 = 0;
    segment->window = 26883; // Voir ce que c'est exactement
    segment->checksum = checksum;
    segment->urgentPointer = 0;

    klee_make_symbolic(&length, sizeof(length), "length");

    // We make a hard copy of the struct to check if the fields have
    // changed after the call to the function
    sModel = toSockModel(socket);

    tcpStateCloseWait(socket, segment, length);

    klee_assert(equalSocketModel(socket, sModel) &&
                (socket->state == TCP_STATE_CLOSE_WAIT ||
                (socket->state == TCP_STATE_CLOSED &&
                 socket->resetFlag)));
}
