#!/bin/bash
##############################################################################
#### Different compute node VM to VM test iperf and dpdk test ################
##############################################################################

##############################################################################
############################### readme_runme.sh ##############################
# A test used to measure the performance between two VM's. The first Vm 
#  should be located on the current node and the second on a different node.
# This file focuses on the general setup for this test. This file also serves 
#  as an executable to set up the environment for the test
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


##############################################################################
# Setup instructions
##############################################################################
# If this readme is executed it will copy the required files to the 
#  appropriate places on each vm and compute node. eg. ./readme_runme.txt
# After the setup has been complete the test can be executed by running
#  ./run_netronome_test
# Note that:
# - This readme should be located on the clien node. This will also be the 
#    the node from which the test is driven.
# - Appropriate permissions should be given to this file. (chmod +x )
# - ssh-keys should be set up between nodes and between nodes and VM's this
#    is to ensure passwordless access
##############################################################################
# Setup Variables                           EDIT THE VARIABLES IN THIS SECTION
##############################################################################

# Compute node info
server_node_ip=172.26.1.111
client_node_ip=172.26.1.112
server_vm_ip=169.254.0.7
client_vm_ip=169.254.0.7

# Server VM - NOTE: THERE SHOULD BE 4 INTERFACES AND 4 IP's
svm_interface_list=( 00:04.0 )    
svm_ip_list=( 80.0.0.3 )

# Client VM - NOTE: THERE SHOULD BE 4 INTERFACES AND 4 IP's
cvm_interface_list=( 00:04.0 )    #
cvm_ip_list=( 80.0.0.4)

# NOTE:
# The physical addresses can be determined by checking the following command
#  readlink -e /sys/class/net/<netdev name>
#Example:
# 
# ~: readlink -e /sys/class/net/eth1
# /sys/devices/pci0000:00/0000:00:04.0/virtio1/net/eth1
#
# The physical address in this case is 0000:00:04.0 and should be 
#  shortend to 00:04.0 and then listed in the interface lists.

##############################################################################
##############################################################################

##############################################################################
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
#XXXXXXXXXXXXXXXXX NO EDITING NECESSARY BEYOND THIS POINT XXXXXXXXXXXXXXXXXXXX
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
##############################################################################

##############################################################################
############################# Passwordless ssh setup #########################
##############################################################################
ssh-keygen
ssh-copy-id "root@"$server_node_ip
ssh-copy-id "root@"$client_node_ip
ssh "root@"$server_node_ip ssh-copy-id "root@"$server_vm_ip
ssh "root@"$client_node_ip ssh-copy-id "root@"$client_vm_ip
##############################################################################


##############################################################################
############################# Server node setup ##############################
##############################################################################
# Edit setup_test.sh for server
echo "Edit setup_test.sh for server"
sed -i "s/^$(grep "^interface_list=" ./setup_test.sh)/interface_list=(${svm_interface_list[@]})/" ./setup_test.sh
sed -i "s/^$(grep "^src_ip_list=" ./setup_test.sh)/src_ip_list=(${svm_ip_list[@]})/" ./setup_test.sh
sed -i "s/^$(grep "^dst_ip_list=" ./setup_test.sh)/dst_ip_list=(${cvm_ip_list[@]})/" ./setup_test.sh

# Copy required files to server node root
echo "Copying required files to server node root"
scp ./run_pktgen.sh "root@"$server_node_ip":/root/"
scp ./load_pps "root@"$server_node_ip":/root/"
scp ./install_igb_uio.sh "root@"$server_node_ip":/root/"
scp ./install_virtio_pci.sh "root@"$server_node_ip":/root/"
scp ./setup_control_node.sh "root@"$server_node_ip":/root/"
scp ./setup_test.sh "root@"$server_node_ip":/root/"

# Copy required files from server node root to server VM root
echo "Copying required files from server node root to server VM root"
ssh "root@"$server_node_ip scp ./run_pktgen.sh "root@"$server_vm_ip":/root/"
ssh "root@"$server_node_ip scp ./load_pps "root@"$server_vm_ip":/root/"
ssh "root@"$server_node_ip scp ./install_igb_uio.sh "root@"$server_vm_ip":/root/"
ssh "root@"$server_node_ip scp ./install_virtio_pci.sh "root@"$server_vm_ip":/root/"
ssh "root@"$server_node_ip scp ./setup_test.sh "root@"$server_vm_ip":/root/"

# Give executable permissions to ./setup_control_node.sh
echo "Giving executable permissions to ./setup_control_node.sh"
ssh "root@"$server_node_ip chmod +x ./setup_control_node.sh

##############################################################################
###############################  Client setup ################################
##############################################################################
# Edit setup_test.sh for server
echo "Editing setup_test.sh for server"
sed -i "s/^$(grep "^interface_list=" ./setup_test.sh)/interface_list=(${cvm_interface_list[@]})/" ./setup_test.sh
sed -i "s/^$(grep "^src_ip_list=" ./setup_test.sh)/src_ip_list=(${cvm_ip_list[@]})/" ./setup_test.sh
sed -i "s/^$(grep "^dst_ip_list=" ./setup_test.sh)/dst_ip_list=(${svm_ip_list[@]})/" ./setup_test.sh

# Copy required files to server node root
echo "Copying required files to server node root"
scp ./run_pktgen.sh "root@"$client_node_ip":/root/"
scp ./load_pps "root@"$client_node_ip":/root/"
scp ./install_igb_uio.sh "root@"$client_node_ip":/root/"
scp ./install_virtio_pci.sh "root@"$client_node_ip":/root/"
scp ./setup_control_node.sh "root@"$client_node_ip":/root/"
scp ./setup_test.sh "root@"$client_node_ip":/root/"

# Copy required files to client VM root
echo "Copying required files to client VM root"
ssh "root@"$client_node_ip scp ./run_pktgen.sh "root@"$client_vm_ip":/root/"
ssh "root@"$client_node_ip scp ./load_pps "root@"$client_vm_ip":/root/"
ssh "root@"$client_node_ip scp ./install_igb_uio.sh "root@"$client_vm_ip":/root/"
ssh "root@"$client_node_ip scp ./install_virtio_pci.sh "root@"$client_vm_ip":/root/"
ssh "root@"$client_node_ip scp ./setup_test.sh "root@"$client_vm_ip":/root/"

# Give executable permissions to ./setup_control_node.sh
echo "Giving executable permissions to ./setup_control_node.sh"
chmod +x ./setup_control_node.sh

#Update ./run_netronome_test.sh
echo "Update ./run_netronome_test.sh"
sed -i "s/^$(grep "^CLIENT_NODE_IP=" ./run_netronome_test.sh)/CLIENT_NODE_IP=$client_node_ip/" ./run_netronome_test.sh
sed -i "s/^$(grep "^SERVER_NODE_IP=" ./run_netronome_test.sh)/SERVER_NODE_IP=$server_node_ip/" ./run_netronome_test.sh
sed -i "s/^$(grep "^SERVER_IP=" ./run_netronome_test.sh)/SERVER_IP=$server_vm_ip/" ./run_netronome_test.sh
sed -i "s/^$(grep "^CLIENT_IP=" ./run_netronome_test.sh)/CLIENT_IP=$client_vm_ip/" ./run_netronome_test.sh

# Give executable permissions to ./run_netronome_test.sh
echo "Giving executable permissions to ./run_netronome_test.sh"
chmod +x ./run_netronome_test.sh

##############################################################################
############################## Local VM setup ################################
##############################################################################
# These scripts continue setting up the tests locally on the vm
echo "Continuing setting up the tests locally on the vm"
ssh "root@"$server_node_ip ssh "root@"$server_vm_ip chmod +x ./setup_test.sh
ssh "root@"$client_node_ip ssh "root@"$client_vm_ip chmod +x ./setup_test.sh

ssh "root@"$server_node_ip ssh "root@"$server_vm_ip ./setup_test.sh &
ssh "root@"$client_node_ip ssh "root@"$client_vm_ip ./setup_test.sh &

sleep 10
echo "Setup complete"