HTTP Client
===========

This HTTP Client is based on Oryx-Embedded Cyclone TCP library 
(https://oryx-embedded.com).
It is made to compile on STM32F769I-dicovery plateform.

Use project
-----------

Use `git clone --recursive <git_repo>` to collect all the sources
needed.

Compilation
-----------

Use `make` to compile the project, and `make flash` to install it
on the STM32 card.

You can see the debug messages by opening a terminal on the card
with `minicom -D /dev/ttyACM0`.

Proof
-----

To prove the correctness of the SPARK code, use `gnatprove -P prove.gpr --level=3`.

Organization of the repository
------------------------------

All the sources need for the compilation are under the folder `src/`. In particular
it contains the C sources of cycloneTCP in the folder `cyclone_tcp/`. The translated
files are under the subdirectory `ada/`. A main function is under `main.c` and is
written to launch and test the C.

An experimentation has also been done with Klee, and the folder `klee/` gathers the
sources needed to run Klee. A makefile is provided to help the compilation. You
might need to comment the line `#include "dns/dns_client.h"` in the file `net.h`
to be able to compile.
