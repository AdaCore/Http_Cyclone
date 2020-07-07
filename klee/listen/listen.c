#include "core/socket.h"
#include "klee/klee.h"
#include "core/tcp_misc.h"
#include <assert.h>
#include <stdlib.h>
#include "model.h"

// I'm not convinced here by what is done by klee. Maybe do something differently can be a good idea

void tcpStateListen(Socket *socket, NetInterface *interface,
                    IpPseudoHeader *pseudoHeader, TcpHeader *segment, size_t length)
{
    uint_t i;
    TcpOption *option;
    TcpSynQueueItem *queueItem;

    //Debug message
    // TRACE_DEBUG("TCP FSM: LISTEN state\r\n");

    //An incoming RST should be ignored
    if (segment->flags & TCP_FLAG_RST)
        return;

    //Any acknowledgment is bad if it arrives on a connection
    //still in the LISTEN state
    if (segment->flags & TCP_FLAG_ACK)
    {
        //A reset segment should be formed for any arriving ACK-bearing segment
        // tcpSendResetSegment(interface, pseudoHeader, segment, length);
        //Return immediately
        return;
    }

    klee_print_expr("socket->synQueue: %p\n", socket->synQueue);

    //Check the SYN bit
    if (segment->flags & TCP_FLAG_SYN)
    {
        //Silently drop duplicate SYN segments
        if (tcpIsDuplicateSyn(socket, pseudoHeader, segment))
            return;

        //Check whether the SYN queue is empty
        if (socket->synQueue == NULL)
        {
            //Allocate memory to save incoming data
            queueItem = memPoolAlloc(sizeof(TcpSynQueueItem));
            //Add the newly created item to the queue
            socket->synQueue = queueItem;
        }
        else
        {
            //Point to the very first item
            queueItem = socket->synQueue;

            //Reach the last item in the SYN queue
            for (i = 1; queueItem->next != NULL; i++)
                queueItem = queueItem->next;

            //Make sure the SYN queue is not full
            if (i >= socket->synQueueSize)
                return;

            //Allocate memory to save incoming data
            queueItem->next = memPoolAlloc(sizeof(TcpSynQueueItem));
            //Point to the newly created item
            queueItem = queueItem->next;
        }

        //Failed to allocate memory?
        if (queueItem == NULL)
            return;

#if (IPV4_SUPPORT == ENABLED)
        //IPv4 is currently used?
        if (pseudoHeader->length == sizeof(Ipv4PseudoHeader))
        {
            //Save the source IPv4 address
            queueItem->srcAddr.length = sizeof(Ipv4Addr);
            queueItem->srcAddr.ipv4Addr = pseudoHeader->ipv4Data.srcAddr;
            //Save the destination IPv4 address
            queueItem->destAddr.length = sizeof(Ipv4Addr);
            queueItem->destAddr.ipv4Addr = pseudoHeader->ipv4Data.destAddr;
        }
        else
#endif
#if (IPV6_SUPPORT == ENABLED)
            //IPv6 is currently used?
            if (pseudoHeader->length == sizeof(Ipv6PseudoHeader))
        {
            //Save the source IPv6 address
            queueItem->srcAddr.length = sizeof(Ipv6Addr);
            queueItem->srcAddr.ipv6Addr = pseudoHeader->ipv6Data.srcAddr;
            //Save the destination IPv6 address
            queueItem->destAddr.length = sizeof(Ipv6Addr);
            queueItem->destAddr.ipv6Addr = pseudoHeader->ipv6Data.destAddr;
        }
        else
#endif
        //Invalid pseudo header?
        {
            //This should never occur...
            return;
        }

        //Initialize next field
        queueItem->next = NULL;
        //Underlying network interface
        queueItem->interface = interface;
        //Save the port number of the client
        queueItem->srcPort = segment->srcPort;
        //Save the initial sequence number
        queueItem->isn = segment->seqNum;
        //Default MSS value
        queueItem->mss = MIN(TCP_DEFAULT_MSS, TCP_MAX_MSS);

        //Get the maximum segment size
        option = tcpGetOption(segment, TCP_OPTION_MAX_SEGMENT_SIZE);

        //Specified option found?
        if (option != NULL && option->length == 4)
        {
            //Retrieve MSS value
            osMemcpy(&queueItem->mss, option->value, 2);
            //Convert from network byte order to host byte order
            queueItem->mss = ntohs(queueItem->mss);

            //Debug message
            // TRACE_DEBUG("Remote host MSS = %" PRIu16 "\r\n", queueItem->mss);

            //Make sure that the MSS advertised by the peer is acceptable
            queueItem->mss = MIN(queueItem->mss, TCP_MAX_MSS);
            queueItem->mss = MAX(queueItem->mss, TCP_MIN_MSS);
        }

        //Notify user that a connection request is pending
        tcpUpdateEvents(socket);

        //The rest of the processing described in RFC 793 will be done
        //asynchronously when socketAccept() function is called
    }
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
    socketListen(socket, 0);

    // Creation of a "random" incomming package
    // We assume the pseudo header is filled with ipv4 addresses

    uint32_t srcAddr, destAddr;
    uint16_t dataLength;
    // IpAddr cannot be null
    klee_make_symbolic(&srcAddr, sizeof(srcAddr), "srcAddr");
    klee_make_symbolic(&destAddr, sizeof(destAddr), "destAddr");
    klee_assume(srcAddr != 0);
    klee_assume(destAddr != 0);
    klee_make_symbolic(&dataLength, sizeof(dataLength), "dataLength");

    pseudoHeader->length = sizeof(Ipv4PseudoHeader);
    pseudoHeader->ipv4Data.srcAddr = srcAddr;
    pseudoHeader->ipv4Data.destAddr = destAddr;
    pseudoHeader->ipv4Data.reserved = 0;
    pseudoHeader->ipv4Data.protocol = 6; // TCP protocol
    pseudoHeader->ipv4Data.length = dataLength;
    pseudoHeader->data[0] = 3;
    pseudoHeader->data[1] = 220;
    pseudoHeader->data[2] = 112;
    pseudoHeader->data[3] = 94;

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

    klee_assert(socket->state == TCP_STATE_LISTEN);

    tcpStateListen(socket, socket->interface, pseudoHeader, segment, length);

    int random;
    klee_make_symbolic(&random, sizeof(int), "random");

    // We see if the assertion is still true if more than one segment has been received
    if (random)
    {
        klee_make_symbolic(&srcAddr, sizeof(srcAddr), "srcAddr");
        klee_make_symbolic(&destAddr, sizeof(destAddr), "destAddr");
        klee_assume(srcAddr != 0);
        klee_assume(destAddr != 0);
        klee_make_symbolic(&dataLength, sizeof(dataLength), "dataLength");

        pseudoHeader->length = sizeof(Ipv4PseudoHeader);
        pseudoHeader->ipv4Data.srcAddr = srcAddr;
        pseudoHeader->ipv4Data.destAddr = destAddr;
        pseudoHeader->ipv4Data.reserved = 0;
        pseudoHeader->ipv4Data.protocol = 6; // TCP protocol
        pseudoHeader->ipv4Data.length = dataLength;
        pseudoHeader->data[0] = 3;
        pseudoHeader->data[1] = 220;
        pseudoHeader->data[2] = 112;
        pseudoHeader->data[3] = 94;

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

        tcpStateListen(socket, socket->interface, pseudoHeader, segment, length);
    }

    klee_assert(equalSocketModel(socket, sModel) &&
                socket->state == TCP_STATE_LISTEN &&
                (socket->synQueue != NULL ? (socket->synQueue->srcAddr.length != 0 &&
                                             socket->synQueue->srcPort > 0 &&
                                             socket->synQueue->destAddr.length != 0)
                                          : 1));
}
