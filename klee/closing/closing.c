#include "core/socket.h"
#include "klee/klee.h"
#include "core/tcp_misc.h"
#include <assert.h>
#include <stdlib.h>
#include "model.h"
#include "core/tcp_timer.h"

void tcpStateClosing(Socket *socket, TcpHeader *segment, size_t length)
{
    //Debug message
    // TRACE_DEBUG("TCP FSM: CLOSING state\r\n");

    //First check sequence number
    if (tcpCheckSequenceNumber(socket, segment, length))
        return;

    //Check the RST bit
    if (segment->flags & TCP_FLAG_RST)
    {
        //Enter CLOSED state
        tcpChangeState(socket, TCP_STATE_CLOSED);
        //Return immediately
        return;
    }

    //Check the SYN bit
    if (tcpCheckSyn(socket, segment, length))
        return;
    //Check the ACK field
    if (tcpCheckAck(socket, segment, length))
        return;

    //If the ACK acknowledges our FIN then enter the TIME-WAIT
    //state, otherwise ignore the segment
    if (segment->ackNum == socket->sndNxt)
    {
        //Release previously allocated resources
        tcpDeleteControlBlock(socket);
        //Start the 2MSL timer
        tcpTimerStart(&socket->timeWaitTimer, TCP_2MSL_TIMER);
        //Switch to the TIME-WAIT state
        tcpChangeState(socket, TCP_STATE_TIME_WAIT);
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

    segment = malloc(sizeof(TcpHeader));

    // creation of a TCP socket
    socket = socketOpen(SOCKET_TYPE_STREAM, SOCKET_IP_PROTO_TCP);

    // TODO: See if it is the correct way to process.
    // Maybe open the connection by following the real call of the function
    // is a better way to do.
    tcpChangeState(socket, TCP_STATE_CLOSING);

    klee_make_symbolic(&ackNum, sizeof(ackNum), "ackNum");
    klee_make_symbolic(&seqNum, sizeof(seqNum), "seqNum");
    klee_make_symbolic(&flags, sizeof(flags), "flags");
    klee_assume(flags >= 0 && flags <= 31);
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

    klee_make_symbolic(&length, sizeof(length), "length");

    // We make a hard copy of the struct to check if the fields have
    // changed after the call to the function
    sModel = toSockModel(socket);

    klee_assert(socket->state == TCP_STATE_CLOSING);

    tcpStateClosing(socket, segment, length);

    klee_assert(equalSocketModel(socket, sModel) &&
                (socket->state == TCP_STATE_CLOSING ||
                 socket->state == TCP_STATE_TIME_WAIT ||
                 (socket->state == TCP_STATE_CLOSED &&
                  socket->resetFlag)));
}
