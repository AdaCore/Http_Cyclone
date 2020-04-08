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

To prove the correctness of the SPARK code, use `make prove`.