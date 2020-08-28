TCP/IP Stack
============

This project is a partial reuse of the Oryx-Embedded Cyclone TCP library (https://oryx-embedded.com)
to create a Ada/SPARK verified library. This library implement a new
interface for sockets as well as a partial reimplementation of the TCP
user functions in SPARK. The absence of run-time errors has been proved
for these functions with SPARK. Moreover, some functional specifications
of the TCP norm have also be proved.

The table below gives an overview of the files that are translated in SPARK,
and then proved and the ones that are only a binding between C and Ada,
to use the existing C library.

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

Use `make` to compile the project, and `make flash` to install it
on the STM32 card.

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

Contribute
----------

Don't hesitate to open a PR to improve the code.
