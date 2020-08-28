HTTP Client
===========

This HTTP Client is based on Oryx-Embedded Cyclone TCP library 
(https://oryx-embedded.com).
It is made to compile on STM32F769I-dicovery plateform.

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
```
anod install SPARK2014
```

To prove the correctness of the SPARK code, use
```
make prove
```
or use the following command line
```
gnatprove -P prove.gpr --level=4 -u tcp_interface.ads -j0 && gnatprove -P prove.gpr --level=3 -j0
```

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

Contribute
----------

Don't hesitate to open a PR to improve the code.
