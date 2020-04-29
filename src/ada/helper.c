#include "core/net.h"
#include "core/socket.h"
#include "core/raw_socket.h"
#include "core/udp.h"
#include "core/tcp.h"
#include "core/tcp_misc.h"
#include "dns/dns_client.h"
#include "mdns/mdns_client.h"
#include "netbios/nbns_client.h"
#include "llmnr/llmnr_client.h"
#include "debug.h"

Socket* getSocketFromTable (unsigned index) {
    return &socketTable[index];
}