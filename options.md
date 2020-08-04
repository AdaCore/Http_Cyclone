List of Options
===============

The following table lists all the options allowed in the configuration file.

Socket Options
--------------

| **Option**         | **Description**                                     | **Range**  | **Default** |
|--------------------|-----------------------------------------------------|------------|-------------|
| `SOCKET_MAX_COUNT` | Number of sockets that can be opened simultaneously | `Positive` | 16          |

TCP Options
-----------

| **Option**               | **Description**                                     | **Range**              | **Default** |
|--------------------------|-----------------------------------------------------|------------------------|-------------|
| `TCP_MAX_RX_BUFFER_SIZE` | Maximum acceptable size for the receive buffer      | 536 .. `Positive'Last` | 22_880      |
| `TCP_DEFAULT_RX_BUFFER_SIZE` | Default buffer size for reception               | 536 .. `TCP_MAX_RX_BUFFER_SIZE` | 2_860 |
| `TCP_MAX_TX_BUFFER_SIZE` | Maximum acceptable size for the send buffer         | 536 .. `Positive'Last` | 22_880      |
| `TCP_DEFAULT_TX_BUFFER_SIZE` | Default buffer size for transmission            | 536 .. `TCP_MAX_TX_BUFFER_SIZE` | 2_860 |
| `TCP_MAX_SYN_QUEUE_SIZE` | Maximum SYN queue size for listening sockets            | 1 .. `Positive'Last` | 16 |
| `TCP_DEFAULT_SYN_QUEUE_SIZE` | Default SYN queue size for listening sockets            | 1 .. `TCP_MAX_SYN_QUEUE_SIZE` | 4 |