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
| `TCP_MAX_MSS` | Maximum segment size            | 536 .. `Short_Integer'Last` | 1430 |
| `TCP_MIN_MSS` | Mimimum acceptable segment size  | 1 .. `Short_Integer'Last` | 64 |
| `TCP_DEFAULT_MSS` | Default SYN queue size for listening sockets            | 1 .. `TCP_MAX_MSS` | 536 |
| `TCP_MAX_RTO` | Maximum retransmission timeout | 1000 .. `unsigned'Last` | 536 |
| `TCP_MIN_RTO` | Minimum retransmission timeout | 100 .. `TCP_MAX_RTO` | 536 |
| `TCP_DEFAULT_MSS` | Initial retransmission timeout | 1 .. `TCP_MAX_RTO` | 536 |
| `TCP_INITIAL_WINDOW` | Size of the congestion window after the three-way handshake is completed | 1 .. 20 | 3 |
