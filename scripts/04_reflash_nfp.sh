#!/bin/bash
# Script to reflash the Arm firmware onto the NFP to enable vRouter offload
# Remove and reload NFP drivers with CPP access
rmmod nfp
modprobe nfp nfp_pf_netdev=0 nfp_dev_cpp=1
#Reflash SmartNIC
echo "Reflashing SmartNIC NFP"
/opt/netronome/bin/nfp-flash --preserve-media-overrides -w /opt/netronome/flash/flash-nic.bin
/opt/netronome/bin/nfp-one
echo "Flash Complete"
