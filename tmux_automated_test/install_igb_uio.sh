#!/bin/bash
##############################################################################
#### Different compute node VM to VM test iperf and dpdk test ################
##############################################################################

##############################################################################
############################# install_igb_uio.sh #############################
# A test used to measure the performance between two VM's. The first Vm 
#  should be located on the current node and the second on a different node.
# This file is used to bind the igb_uio driver
##############################################################################
# File Requirements on VM's:
# - ~/load_pps                      - Setup pktgen header
# - ~/run_pktgen.sh                 - Start pktgen
# - ~/install_igb_uio.sh            - Install igb_uio driver
# - ~/install_virtio_pci.sh         - install virtio-pci driver
# - ~/setup_test.sh                 - Sets up test locally
##############################################################################
# File Requirements on control/compute nodes
# - ~/setup_control_node.sh         - Sets up the control node locally
# - ~/run_netronome_test.sh         - Start the automated test
##############################################################################
# Setup Requirements:
# - 2 VM's, each on his own node
# - Atleast 4 networks/interfaces connecting the two VM's
# - Installed on VM:
#       DPDK
#       DPDK-pktgen
#       iperf
##############################################################################
# Company : Netronome
# Author  : Iwan de Klerk
# Contact : iwan(dot)deklerk(at)netronome(dot)com
##############################################################################

interface_list=(00:04.0 00:05.0 00:06.0 00:07.0)
driver=igb_uio
mp=uio

# Makes sure all netdevs are down
for interface in ${interface_list[@]}
do
    readlink -f "/sys/devices/pci0000:00/0000:"$interface"/driver" | grep -q "virtio-pci"
    if [ $? == 0 ]
    then
        virtio_folder=$(ls "/sys/devices/pci0000:00/0000:"$interface"/" | grep virtio)
        netdev=$(ls "/sys/devices/pci0000:00/0000:"$interface"/"$virtio_folder"/net/")
        ifconfig $netdev down
    fi
done

##############################################################################
# Bind all interfaces to igb_uio
##############################################################################
#Summary:
# To bind driver:
# dpdk-16.11/tools/dpdk-devbind.py --bind igb_uio <interface>
##############################################################################
DPDK_DEVBIND=$(find ~ -iname dpdk-devbind.py | head -1)
DRKO=$(find ~ -iname 'igb_uio.ko' | head -1 )
echo "loading driver"
modprobe $mp
insmod $DRKO
modprobe igb_uio
echo "DPDK_DEVBIND: $DPDK_DEVBIND"
for interface in ${interface_list[@]};
do
  echo $DPDK_DEVBIND --bind $driver $interface
  $DPDK_DEVBIND --bind $driver $interface
done
echo $DPDK_DEVBIND --status
$DPDK_DEVBIND --status
##############################################################################
