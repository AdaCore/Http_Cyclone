#include "core/net.h"
#include "drivers/mac/stm32f7xx_eth_driver.h"
#include "drivers/phy/lan8742_driver.h"
#include "dhcp/dhcp_client.h"
#include "ipv6/slaac.h"
#include "ftp/ftp_client.h"

error_t HttpClientTest(const char_t * serverName, const char_t * uri) {
   error_t error;          //Code d'erreur
   char_t buffer[128];     //Buffer de transmission
   size_t length;          //Longeur du buffer
   IpAddr serverIpAddr;    //Adresse IP du serveur HTTP
   Socket *socket;         //Socket pour la communication client-serveur

   // Récupération du nom de l'hôte
//    error = getHostByName(NULL, serverName, &serverIpAddr, 0);
//    if (error) {
//       printf("ERROR: getHostByName.\r\n");
//       return error;
//    }

   // Ouverture de la socket
   socket = socketOpen(SOCKET_TYPE_STREAM, SOCKET_IP_PROTO_TCP);
   if (!socket) {
      printf("Error: socketOpen.\r\n");
      return ERROR_FAILURE;
   }

   // Timeout de 30 secondes
   error = socketSetTimeout(socket, 30000);
   if (error) {
      printf("ERROR: socketSetTimeout.\r\n");
      goto closesocket;
   }

   error = socketConnect(socket, &serverIpAddr, 80);
   if (error) {
      printf("ERROR: socketConnect.\r\n");
      goto closesocket;
   }

   // creation de la requête vers la page souhaitée
   length = snprintf(buffer, 128, 
      "GET %s HTTP/1.1\r\nHost: %s\r\nConnection: close\r\n\r\n", 
      uri, serverName);

   // envoi de la requête HTTP
   error = socketSend(socket, buffer, length, NULL, 0);
   if (error) {
      printf("ERROR: socketSend.\r\n");
      goto closesocket;
   }

   printf("Reception of the Data...\r\n");

   while (1) 
   {
      // Reception du résultat de la requête
      error = socketReceive(socket, buffer, 127, &length, 0);
      if (error) {
         break;
      }
      buffer[length] = '\0';

      printf("%s", buffer);
   }
   printf("\n");

   // Fermeture de la socket
   error = socketShutdown(socket, SOCKET_SD_BOTH);
   if (error) {
      printf("ERROR: socketShutdown.\n");
   }

closesocket:
   socketClose(socket);
   return error;
}

int main() {
    error_t error;

    error = HttpClientTest("httpbin.org", "/anything");
}