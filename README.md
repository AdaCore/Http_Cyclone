TCP/IP Stack
============

The project demonstrates how existing software libraries written in C programming language can be hardened in terms of  software assurance and security by the use of the Ada and SPARK technologies. 

The [Oryx Embedded CycloneTCP](https://oryx-embedded.com) library is used as a starting point. CycloneTCP is a professional-grade embedded Transmission Control Protocol/Internet Protocol (TCP/IP) library developed by the Oryx Embedded company. The implementation is meant to conform with the Request for Comments (RFC) Internet standards, namely the [RFC 793 TCP](https://tools.ietf.org/html/rfc793) protocol specifications,  provided by the Internet Engineering Task Force ([IETF](https://tools.ietf.org/)). The library is written in ANSI C, and it supports a large number of 32-bit embedded processors and a large number of Real-time Operating systems (RTOS). It can also run in a bare-metal environment. The library offers implementations for a wide range of TCP/IP protocols. A quick overview of the library can be found [here](https://www.oryx-embedded.com/products/CycloneTCP.html). 

A new implementation of the library's socket interface and a partial implementation of the TCP user functions is provided in SPARK. The absence of run-time errors for the translated functions and the conformance to some functional specifications of the TCP norm is proved using the SPARK technologies.

Repository Organization
----------------------------

All the source files need for the compilation are located under the folder `src/`. In particular, this folder contains the C source files of the CycloneTCP library under the folder `cyclone_tcp/`. The translated to Ada/SPARK files are located under the subdirectory `ada/`. The demo's main function is located in the `main.c` file. The example can compile for the two currently supported development boards: the STM32F769I-Discovery and the stm32f407-Discovery platforms.

The KLEE symbolic execution engine was used to gain confidence that the C code conforms with the protocol's functional specifications. The folder named  `klee/` includes all the source files needed to run Klee. A makefile is provided to help with the compilation. The line `#include "dns/dns_client.h"` in the file `net.h` might needed to be commented-out to be able to compile. By using the SPARK technologies, the code configured by the `config.def` file will be proved. 

The table below gives an overview of the files that are translated in SPARK and then proved. It also records all the files that offer the necessary bindings between C and Ada to facilitate the interface between the two languages.

| File                    | Description                                                       | Translation or binding                   |
|-------------------------|-------------------------------------------------------------------|------------------------------------------|
| ada_main.adb            | Customer SPARK code using the socket API.                         | SPARK code.                              |
| socket_types.ads        | Types and structure of a socket.                                  | SPARK code                               |
| socket_interface.adb    | Socket API.                                                       | SPARK code.                              |
| socket_helper.ads       | Helper function for proofs.                                       | Helper functions for proofs.             |
| tcp_type.ads            | Types used for TCP.                                               | SPARK code.                              |
| tcp_interface.adb       | TCP user functions.                                               | SPARK code.                              |
| tcp_misc_binding.adb    | Helper functions for TCP.                                         | SPARK code / binding to C code.          |
| tcp_fsm_binding.ads     | TCP finite state machine. Functions to process incoming segments. | Binding to C code.                       |
| tcp_timer_interface.ads | Simulate a timer tick.                                            | SPARK code. Helper functions for proofs. |
| udp_binding.adb         | UDP functions.                                                    | Binding to C code.                       |
| net_mem_interface.adb   | Memory management.                                                | Binding to C code.                       |
| ip_binding.adb          | Underlaying IP layer functions.                                   | Binding to C code.                       |


Get the project
-----------

Use `git clone --recursive <git_repo>` to collect all the source files
needed.

Dependencies
-----------

The following tools are needed to compile the project:
* GNAT ARM 2020 (download it here https://www.adacore.com/download and install it in the recommended location).
* OpenOCD to flash on the card (tested with version 2.7.1).
* *[Optional]* minicom to see the debug messages (tested with version 0.10.0).

*[Optional]* For the verification:
* KLEE + LLVM 6
* SPARK Pro 22.0w (20201110)

Configuration
-------------

The TCP-related  configuration options can be set in the file `config.def`,
in the format:
```
OPTION := VALUE
```
A description of all the available options can be found in the file
[options.md](options.md).

Before compiling or running `gnatprove`, it is necessary to run
```
make config
```
to add the correct files to the compilation.

Compilation
-----------

The arm Ada compiler needs to be installed for compiling the project. This can be found [here](https://www.adacore.com/download). Please install it at the recommended location.

If the ARM compiler is not installed in the default directory, you can use
`make RTS=<install_dir>` to help the compiler to find the require files
for the compilation.

The current implementation supports two development boards, namely, the stm32f407 and the stm32f769i_discovery. To select which board to compile for, please run:
```
$ ./configure.sh
Chose the development board to be used for compiling the Http_Cyclone demo.
[a] stm32f407_discovery
[b] stm32f769i_discovery
Please, select an option:
```
Then to compile the project execute:
```
make
```
To flash the program onto the STM32 board:
```
make flash
```
To view debug messages on the host PC, use:
```
minicom -D /dev/ttyACM0
```

Proof
-----
To prove the SPARK code, use:
```
make prove
```
or use the following command line:
```
gnatprove -P prove.gpr --level=4 -j0
```
The code configured by the `config.def` will be proved.


Demo
-------

The demo downloads an HTTP page and prints it. To view the printing, you must install and use the `minicom` tool. To launch the demo, press the blue button on the development board. The page will be displayed as an HTTP request: the header followed by the content of the
page in JSON format will be printed.

