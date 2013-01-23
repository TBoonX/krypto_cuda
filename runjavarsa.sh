#!/bin/bash
##for i in 01 02 03 04 05 06 07 08 09 {10..11}
for i in 1 2 4 8 16 32 64 128 256 512 1024 2048 4096
do
	echo "[n $i ] `java -jar rsa_java.jar -f klartext -n $i`"
done
