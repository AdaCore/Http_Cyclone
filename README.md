TCP/IP Stack
============

The project demonstrates how existing software libraries written in C programming language can be hardened in terms of  software assurance and security by the use of the Ada and SPARK technologies. 

The [Oryx Embedded CycloneTCP](https://oryx-embedded.com) library is used as a starting point. CycloneTCP is a professional-grade embedded Transmission Control Protocol/Internet Protocol (TCP/IP) library developed by the Oryx Embedded company. The implementation is meant to conform with the Request for Comments (RFC) Internet standards, namely the [RFC 793 TCP](https://tools.ietf.org/html/rfc793) protocol specifications,  provided by the Internet Engineering Task Force ([IETF](https://tools.ietf.org/)). The library is written in ANSI C, and it supports a large number of 32-bit embedded processors and a large number of Real-time Operating systems (RTOS). It can also run in a bare-metal environment. The library offers implementations for a wide range of TCP/IP protocols. A quick overview of the library can be found [here](https://www.oryx-embedded.com/products/CycloneTCP.html). 

A new implementation of the library's socket interface and a partial implementation of the TCP user functions is provided in SPARK. The absence of run-time errors for the translated functions and the conformance to some functional specifications of the TCP norm is proved using the SPARK technologies.

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

Use project
-----------

Use `git clone --recursive <git_repo>` to collect all the sources
needed.

The following tools are needed to compile the project:
* GNAT ARM 2020 (download it here https://www.adacore.com/download and install it in the recommanded location).
* OpenOCD to flash on the card
* *[Optional]* minicom to see the debug messages.

*[Optional]* For the verification:
* KLEE + LLVM 6.
* SPARK.

Configuration
-------------

The configuration options has to be set in the file `config.def`,
in the format
```
OPTION := VALUE
```
A description of all the available option can be found in the file
[options.md](options.md).

Before compiling or running `gnatprove`, it is necessary to run
```
make config
```
to add the correct files to the compilation.

Compilation
-----------

To compile the project, you need to have installed the arm compiler for
ada, that can be found here https://www.adacore.com/download. Install it
in the recommanded location.

First, you have to chose the board:
```
$ ./configure
Chose your material in the list below to configure the Http_Cyclone demo.
[a] stm32f407
[b] stm32f769i_discovery
Select your material:
```
Then to compile the project:
```
make
```
To install it on the STM32 card:
```
make flash
```

If the ARM compiler is not installed in the default directory, you can use
`make RTS=<install_dir>` to help the compiler to find the require files
for the compilation.

You can see the debug messages by opening a terminal on the card
with `minicom -D /dev/ttyACM0`.

Proof
-----

To use SPARK, it's require to have a recent version of SPARK because delta aggregates
are used in the code.

To prove the correctness of the SPARK code, use
```
make prove
```
or use the following command line
```
gnatprove -P prove.gpr --level=4 -j0
```
The code corresponding to the configuration defined in the file `config.def` will be proved.

Organization of the repository
------------------------------

All the sources need for the compilation are under the folder `src/`. In particular
it contains the C sources of cycloneTCP in the folder `cyclone_tcp/`. The translated
files are under the subdirectory `ada/`. A main function is under `main.c` and is
written to launch and test the C. The example is made to compile on STM32F769I-dicovery plateform.

An experimentation has also been done with Klee, and the folder `klee/` gathers the
sources needed to run Klee. A makefile is provided to help the compilation. You
might need to comment the line `#include "dns/dns_client.h"` in the file `net.h`
to be able to compile.

Example
-------

The code example a HTTP page and print it. To see the result, you must install minicom.
Click on the blue button on the board to launch the download.
The page is displayed as a HTTP request: the header followed by the content of the
page in JSON format.


Contribute
----------

Don't hesitate to open a PR to improve the code.
