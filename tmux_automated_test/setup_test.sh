#!/bin/bash
##############################################################################
#### Different compute node VM to VM test iperf and dpdk test ################
##############################################################################

##############################################################################
############################### setup_test.sh ################################
# A test used to measure the performance between two VM's. The first Vm 
#  should be located on the current node and the second on a different node.
# This file focuses on the setup on the vm. Specifically a setup required to 
#  perform the tests.
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

interface_list=( 00:04.0 00:05.0 00:06.0 00:07.0 )
src_ip_list=( 10.10.2.5 10.10.3.5 10.10.4.5 10.10.5.5 )
dst_ip_list=( 10.10.2.6 10.10.3.6 10.10.4.6 10.10.5.6 )

# Modify ./install_igb_uio.sh
# The script used to install the igb_uio drivers
echo "Adding interface information to igb_uio.sh"
echo sed -i \' 's/^'$(grep "^interface_list=" ./install_igb_uio.sh)'/interface_list=('$(echo ${interface_list[@]})')/'\' ./install_igb_uio.sh | sh
chmod +x ./install_igb_uio.sh

# Modify ./install_virtio_pci.sh
# The script used to install the virtio-pci drivers
echo "Adding interface information to virtio-pci.sh"
echo sed -i \' 's/^'$(grep "^interface_list=" ./install_virtio_pci.sh)'/interface_list=('$(echo ${interface_list[@]})')/'\' ./install_virtio_pci.sh | sh
echo sed -i \' 's/^'$(grep "^ip_list=" ./install_virtio_pci.sh)'/ip_list=('$(echo ${src_ip_list[@]})')/'\' ./install_virtio_pci.sh | sh
chmod +x ./install_virtio_pci.sh
./install_virtio_pci.sh > /dev/null
sleep 5

# Modify ./load_pps
# The script used to load pktgen with the correct header info
echo "Adding interface information to load_pps"
for portnr in $(seq 0 $((${#interface_list[@]}-1)))
do
    echo sed -i \' 's/^'$(grep "^set ip src "$portnr ./load_pps | cut -d "/" -f 1)'/set ip src '$portnr' '${src_ip_list[$portnr]}'/'\' ./load_pps | sh
    echo sed -i \' 's/^'$(grep "^set ip dst "$portnr ./load_pps)'/set ip dst '$portnr' '${dst_ip_list[$portnr]}'/'\' ./load_pps | sh
    ping -c 1 ${dst_ip_list[$portnr]} > /dev/null
    dst_mac=$(arp -an | grep ${dst_ip_list[$portnr]} | grep -o "..:..:..:..:..:..")
    echo sed -i \' 's/^'$(grep "^set mac "$portnr ./load_pps)'/set mac '$portnr' '$dst_mac'/'\' ./load_pps | sh
done

# Modify ./run_pktgen.sh
# The script used to launch pktgen with the correct parameters
echo "Adding interface information to run_pktgen"
temp_list=($(echo ${interface_list[@]} | awk '{ for(i = 1; i <= NF; i++) { print "-w 0000:" $i; } }'))
echo sed -i \' 's/^'$(grep "^whitelist=" ./run_pktgen.sh)'/interface_list=('$(echo ${temp_list[@]})')/'\' ./run_pktgen.sh | sh
chmod +x ./run_pktgen.sh