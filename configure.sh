#!/bin/sh

cat << EOF
Chose the development board to be used for compiling the Http_Cyclone demo.
[a] stm32f407_discovery
[b] stm32f769i_discovery
EOF

read -p 'Please, select an option: ' material

if [ $material = 'a' -o $material = 'A' ]
then
    echo 'Done. Run "make" to compile the demo.'
    cp Makefile.stm32f4xx Makefile
elif [ $material = 'b' -o $material = 'B' ]
then
    echo 'Done. Run "make" to compile the demo.'
    cp Makefile.stm32f7xx Makefile
else
    echo 'Unsupported option.'
fi
