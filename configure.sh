#!/bin/sh

cat << EOF
Chose your material in the list below to configure the Http_Cyclone demo.
[a] stm32f407
[b] stm32f769i_discovery
EOF

read -p 'Select your material: ' material

if [ $material = 'a' -o $material = 'A' ]
then
    echo 'Done. Run "make" to compile the demo'
    cp Makefile.stm32f4xx Makefile
elif [ $material = 'b' -o $material = 'B' ]
then
    echo 'Done. Run "make" to compile the demo'
    cp Makefile.stm32f7xx Makefile
else
    echo 'Your material is not supported'
fi
