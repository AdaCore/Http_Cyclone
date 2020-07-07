#include "model.h"
#include <stdlib.h>

struct socketModel* toSockModel(Socket* socket) {
    struct socketModel* sModel;
    sModel = malloc(sizeof(struct socketModel));

    sModel->localIpAddr.length = socket->localIpAddr.length;
    sModel->localIpAddr.ipv4Addr = socket->localIpAddr.ipv4Addr;
    sModel->localPort = socket->localPort;
    sModel->protocol = socket->protocol;
    sModel->remoteIpAddr.length = socket->remoteIpAddr.length;
    sModel->remoteIpAddr.ipv4Addr = socket->remoteIpAddr.ipv4Addr;
    sModel->remotePort = socket->remotePort;
    sModel->type = socket->type;

    return sModel;
}

int equalSocketModel(Socket* socket, struct socketModel* sModel) {
    return 
        (sModel->localIpAddr.length == socket->localIpAddr.length &&
        sModel->localIpAddr.ipv4Addr == socket->localIpAddr.ipv4Addr &&
        sModel->localPort == socket->localPort &&
        sModel->protocol == socket->protocol &&
        sModel->remoteIpAddr.ipv4Addr == socket->remoteIpAddr.ipv4Addr &&
        sModel->remoteIpAddr.length == socket->remoteIpAddr.length &&
        sModel->remotePort == socket->remotePort &&
        sModel->type == socket->type);
}