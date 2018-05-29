#!/bin/bash
# Echos connected NFP devices
BDFS=$({ lspci -Dnnd 19ee:4000; lspci -Dnnd 19ee:6000; } | cut -f 1 -d " ")
for i in $BDFS; do ls /sys/bus/pci/drivers/nfp/$i/net/; done

