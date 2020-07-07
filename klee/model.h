#include "core/socket.h"

struct socketModel {
    uint_t type;
    uint_t protocol;
    IpAddr localIpAddr;
    uint16_t localPort;
    IpAddr remoteIpAddr;
    uint16_t remotePort;
};

struct socketModel* toSockModel(Socket* socket);

int equalSocketModel(Socket* socket, struct socketModel* sModel);