#!/bin/bash
##############################################################################
#### Different compute node VM to VM test iperf and dpdk test ################
##############################################################################

##############################################################################
########################### install_virtio_uio.sh ############################
# A test used to measure the performance between two VM's. The first Vm 
#  should be located on the current node and the second on a different node.
# This file is used to bind the virtio-pci driver
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
ip_list=( 10.10.2.5 10.10.3.5 10.10.4.5 10.10.5.5 )
cpu_offset=1
cpu_total=5
driver=virtio-pci
DPDK_DEVBIND=$(find ~ -iname dpdk-devbind.py | head -1)
echo "DPDK_DEVBIND: $DPDK_DEVBIND"


##############################################################################
# Bind all interfaces to virtio-pci
##############################################################################
#Summary:
# To bind driver:
# dpdk-16.11/tools/dpdk-devbind.py --bind virtio-pci <interface>
##############################################################################
for interface in ${interface_list[@]};
do
  echo $DPDK_DEVBIND --bind $driver $interface
  $DPDK_DEVBIND --bind $driver $interface
done
echo $DPDK_DEVBIND --status
$DPDK_DEVBIND --status
##############################################################################


##############################################################################
# Setup the netdevs
##############################################################################
for interNr in $(seq 0 $((${#interface_list[@]}-1)))
do
    interface=${interface_list[$interNr]}
    interface_ip=${ip_list[$interNr]}
    virtio_folder=$(ls "/sys/devices/pci0000:00/0000:"$interface"/" | grep virtio)
    netdev=$(ls "/sys/devices/pci0000:00/0000:"$interface"/"$virtio_folder"/net/")
    ifconfig $netdev $interface_ip up
    ifconfig $netdev netmask 255.255.255.0

    irqNr=$(grep $virtio_folder"-input.0" /proc/interrupts | cut -d ":" -f 1 | cut -d " " -f 2)
    echo $(($interNr%($cpu_total-$cpu_offset)+$cpu_offset)) > "/proc/irq/"$irqNr"/smp_affinity_list"
done
##############################################################################

# Making sure irqbalance server is stopped
service irqbalance stop