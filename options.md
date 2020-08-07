List of Options
===============

The following table lists all the options allowed in the configuration file.

Socket Configuration
--------------------

| **Option**         | **Description**                                      | **Range**  | **Default** |
|--------------------|------------------------------------------------------|------------|-------------|
| `SOCKET_MAX_COUNT` | Number of sockets that can be opened simultaneously. | `Positive` | 16          |

TCP Configuration
-----------------

| **Option**               | **Description**                                     | **Range**              | **Default** |
|--------------------------|-----------------------------------------------------|------------------------|-------------|
| `TCP_MAX_MSS` | Maximum segment size. | 536 .. `Short_Integer'Last` | 1430 |
| `TCP_DEFAULT_RX_BUFFER_SIZE` | Default buffer size for reception, in bytes. It is preferable to use a multiple of the MSS for efficiency purpose. | 536 .. 22880 | 2860 |
| `TCP_DEFAULT_TX_BUFFER_SIZE` | Default buffer size for transmission, in bytes. It is preferable to use a multiple of the MSS for efficiency purpose. | 536 .. 22880 | 2860 |
| `TCP_MAX_SYN_QUEUE_SIZE` | Maximum SYN queue size for listening sockets.        | 1 .. `Positive'Last` | 16 |
| `TCP_DEFAULT_SYN_QUEUE_SIZE` | Default SYN queue size for listening sockets.            | 1 .. `TCP_MAX_SYN_QUEUE_SIZE` | 4 |
| `TCP_INITIAL_RTO` | (in milliseconds). This value can be increased up to 3s to accommodate high latency networks. | 1 .. `TCP_MAX_RTO` | 536 |
| `TCP_MAX_RTO` | Maximum retransmission timeout (in milliseconds). | 1000 .. `unsigned'Last` | 536 |
| `TCP_MIN_RTO` | Minimum retransmission timeout (in milliseconds). | 100 .. `TCP_MAX_RTO` | 1000 |

UDP Configuration
-----------------

| Option | Description | Range | Default |
|--------|-------------|-------|---------|
| `UDP_SUPPORT` | This switch adds or removes support for UDP. | `True`/`False` | True |
