#include "core/socket.h"
#include "klee/klee.h"
#include <assert.h>
// #include "core/tcp_fsm.h"
#include <stdlib.h>

error_t tcpSendResetSegmentBis(NetInterface *interface,
   IpPseudoHeader *pseudoHeader, TcpHeader *segment, size_t length)
{
   error_t error;
   size_t offset;
   uint8_t flags;
   uint32_t seqNum;
   uint32_t ackNum;
   NetBuffer *buffer;
   TcpHeader *segment2;
   IpPseudoHeader pseudoHeader2;

   //Check whether the ACK bit is set
   if(segment->flags & TCP_FLAG_ACK)
   {
      //If the incoming segment has an ACK field, the reset takes
      //its sequence number from the ACK field of the segment
      flags = TCP_FLAG_RST;
      seqNum = segment->ackNum;
      ackNum = 0;
   }
   else
   {
      //Otherwise the reset has sequence number zero and the ACK field is set to
      //the sum of the sequence number and segment length of the incoming segment
      flags = TCP_FLAG_RST | TCP_FLAG_ACK;
      seqNum = 0;
      ackNum = segment->seqNum + length;

      //Advance the acknowledgment number over the SYN or the FIN
      if(segment->flags & TCP_FLAG_SYN)
         ackNum++;
      if(segment->flags & TCP_FLAG_FIN)
         ackNum++;
   }

   //Allocate a memory buffer to hold the reset segment
   buffer = ipAllocBuffer(sizeof(TcpHeader), &offset);
   //Failed to allocate memory?
   if(buffer == NULL)
      return ERROR_OUT_OF_MEMORY;

   //Point to the beginning of the TCP segment
   segment2 = netBufferAt(buffer, offset);

   //Format TCP header
   segment2->srcPort = htons(segment->destPort);
   segment2->destPort = htons(segment->srcPort);
   segment2->seqNum = htonl(seqNum);
   segment2->ackNum = htonl(ackNum);
   segment2->reserved1 = 0;
   segment2->dataOffset = 5;
   segment2->flags = flags;
   segment2->reserved2 = 0;
   segment2->window = 0;
   segment2->checksum = 0;
   segment2->urgentPointer = 0;

#if (IPV4_SUPPORT == ENABLED)
   //Destination address is an IPv4 address?
   if(pseudoHeader->length == sizeof(Ipv4PseudoHeader))
   {
      //Format IPv4 pseudo header
      pseudoHeader2.length = sizeof(Ipv4PseudoHeader);
      pseudoHeader2.ipv4Data.srcAddr = pseudoHeader->ipv4Data.destAddr;
      pseudoHeader2.ipv4Data.destAddr = pseudoHeader->ipv4Data.srcAddr;
      pseudoHeader2.ipv4Data.reserved = 0;
      pseudoHeader2.ipv4Data.protocol = IPV4_PROTOCOL_TCP;
      pseudoHeader2.ipv4Data.length = HTONS(sizeof(TcpHeader));

      //Calculate TCP header checksum
      segment2->checksum = ipCalcUpperLayerChecksumEx(&pseudoHeader2.ipv4Data,
         sizeof(Ipv4PseudoHeader), buffer, offset, sizeof(TcpHeader));
   }
   else
#endif
#if (IPV6_SUPPORT == ENABLED)
   //Destination address is an IPv6 address?
   if(pseudoHeader->length == sizeof(Ipv6PseudoHeader))
   {
      //Format IPv6 pseudo header
      pseudoHeader2.length = sizeof(Ipv6PseudoHeader);
      pseudoHeader2.ipv6Data.srcAddr = pseudoHeader->ipv6Data.destAddr;
      pseudoHeader2.ipv6Data.destAddr = pseudoHeader->ipv6Data.srcAddr;
      pseudoHeader2.ipv6Data.length = HTONL(sizeof(TcpHeader));
      pseudoHeader2.ipv6Data.reserved = 0;
      pseudoHeader2.ipv6Data.nextHeader = IPV6_TCP_HEADER;

      //Calculate TCP header checksum
      segment2->checksum = ipCalcUpperLayerChecksumEx(&pseudoHeader2.ipv6Data,
         sizeof(Ipv6PseudoHeader), buffer, offset, sizeof(TcpHeader));
   }
   else
#endif
   //Destination address is not valid?
   {
      //Free previously allocated memory
      netBufferFree(buffer);
      //This should never occur...
      return ERROR_INVALID_ADDRESS;
   }

   //Total number of segments sent
   // MIB2_INC_COUNTER32(tcpGroup.tcpOutSegs, 1);
   // TCP_MIB_INC_COUNTER32(tcpOutSegs, 1);
   // TCP_MIB_INC_COUNTER64(tcpHCOutSegs, 1);

   // //Number of TCP segments sent containing the RST flag
   // MIB2_INC_COUNTER32(tcpGroup.tcpOutRsts, 1);
   // TCP_MIB_INC_COUNTER32(tcpOutRsts, 1);

   //Debug message
   // TRACE_DEBUG("%s: Sending TCP reset segment...\r\n",
   //    formatSystemTime(osGetSystemTime(), NULL));
   //Dump TCP header contents for debugging purpose
   // tcpDumpHeader(segment2, length, 0, 0);

   //Send TCP segment
   // error = ipSendDatagram(interface, &pseudoHeader2, buffer, offset,
   //    &NET_DEFAULT_ANCILLARY_DATA);

   //Free previously allocated memory
   netBufferFree(buffer);

   //Return error code
   return error;
}

void tcpStateClosed(NetInterface *interface,
   IpPseudoHeader *pseudoHeader, TcpHeader *segment, size_t length)
{
   //Debug message
   // TRACE_DEBUG("TCP FSM: CLOSED state\r\n");

   //An incoming segment not containing a RST causes
   //a reset to be sent in response
   if(!(segment->flags & TCP_FLAG_RST))
      tcpSendResetSegmentBis(interface, pseudoHeader, segment, length);
}

int main() {
   // Initialisation
   socketInit();
   
   Socket* socket;
   IpPseudoHeader *pseudoHeader;
   TcpHeader *segment;
   size_t length;
   uint32_t ackNum, seqNum;
   uint8_t flags;
   uint16_t checksum;

   pseudoHeader = malloc(sizeof(IpPseudoHeader));
   segment = malloc(sizeof(TcpHeader));

   // Creation of a TCP socket
   socket = socketOpen(SOCKET_TYPE_STREAM, SOCKET_IP_PROTO_TCP);

   // We should already be in the desired state after the opening
   // of the connection
   klee_assert(socket->state == TCP_STATE_CLOSED);

   // Creation of a "random" incomming package
   pseudoHeader->length = 12;
   pseudoHeader->ipv4Data.srcAddr = 1584454659;
   pseudoHeader->ipv4Data.destAddr = 3430877706;
   pseudoHeader->ipv4Data.reserved = 0;
   pseudoHeader->ipv4Data.protocol = 6; // TCP protocol
   pseudoHeader->ipv4Data.length = 6144;
   pseudoHeader->data[0] = 3;
   pseudoHeader->data[1] = 220;
   pseudoHeader->data[2] = 112;
   pseudoHeader->data[3] = 94;

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

   // it's the length of the data received. We can assume it's something random
   length = 0;

   tcpStateClosed(socket->interface, pseudoHeader, segment, length);

   klee_assert(socket->state == TCP_STATE_CLOSED);
   
   return 0;
}