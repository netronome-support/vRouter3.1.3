#!/bin/bash
##############################################################################
#### Different compute node VM to VM test iperf and dpdk test ################
##############################################################################

##############################################################################
############################ setup_control_node.sh ###########################
# A test used to measure the performance between two VM's. The first Vm 
#  should be located on the current node and the second on a different node.
# This file focuses on the setup of the compute nodes. Specifically the 
#  performance tuning needed to perform optimal test
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

const_virtiorelayd_cpus=2
non_iso_cpu=1
echo
echo "Attempting to verify current setup"
# Get information
cpu_string=$(cat /sys/class/net/nfp_fallback/device/local_cpulist)
cpu_list=($(echo $cpu_string | perl -pe 's/(\d+)-(\d+)/join(",",$1..$2)/eg' | sed 's/,/ /g'))
cpu_list=(${cpu_list[@]:$non_iso_cpu})
cpu_counter=0

##############################################################################
####################### Assign CPU’s to VirtioRelay ##########################
##############################################################################
# Summary of the following code:
#  To view current virtiorelay cpu's
#   cat /etc/default/virtiorelayd | grep '^VIRTIORELAYD_CPU_MASK='
#  To set current virtiorelay cpu's
#   sed 's/^VIRTIORELAYD_CPU_MASK=[0-9/,/-]*/VIRTIORELAYD_CPU_MASK='<virtio_cpu_list>'/' -i /etc/default/virtiorelayd
##############################################################################
echo
echo "Verify VirtioRelay CPU assignment"
virtiorelayd_current_cpu_string=$(cat /etc/default/virtiorelayd | grep -o '^VIRTIORELAYD_CPU_MASK=[0-9/,/-]*' | grep -o '[0-9/,/-]*')
virtiorelayd_current_cpu_list=($(echo $virtiorelayd_current_cpu_string | perl -pe 's/(\d+)-(\d+)/join(",",$1..$2)/eg' | sed 's/,/ /g'))
assign_new_values=0
for virtio_cpu in ${virtiorelayd_current_cpu_list[@]}
do
    if [ $(echo ${cpu_list[@]} | grep '\b'$virtio_cpu'\b' | wc -l) == 0 ]
    then
        assign_new_values=1
        echo "Virtio CPU not in correct range, can cause poor performance"
    fi
done

if [ $assign_new_values == 1 ]
then
    tmp_cpu_list=$(echo ${cpu_list[@]:$cpu_counter:$const_virtiorelayd_cpus} | sed 's/ /,/g' )
    echo "Assign VIRTIORELAYD_CPU_MASK="$tmp_cpu_list
    while true; do
        read -p "Continue? " ans
        case $ans in
            [Yy]* ) 
                sed 's/^VIRTIORELAYD_CPU_MASK=[0-9/,/-]*/VIRTIORELAYD_CPU_MASK='$tmp_cpu_list'/' -i /etc/default/virtiorelayd
                cpu_counter=$(($cpu_counter+$const_virtiorelayd_cpus))
                break;;
            [Nn]* ) 
                break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
else
    echo "Detected virtiorelayd CPU's in correct range"
    echo "VIRTIORELAYD_CPU_MASK="$(echo ${virtiorelayd_current_cpu_list[@]} | sed 's/ /,/g' )
    for virtio_cpu in ${virtiorelayd_current_cpu_list[@]}
    do
        cpu_list=($(echo ${cpu_list[@]} | sed 's/\b'$virtio_cpu'\b/ /g' ))
        cpu_list=($(echo ${cpu_list[@]} | sed 's/^/'$virtio_cpu' /g' ))
        cpu_counter=$(($cpu_counter+1))
    done
fi
##############################################################################


##############################################################################
# Disable IRQ Balancing
##############################################################################
echo 
echo "Stopping irqbalance service"
service irqbalance stop 
##############################################################################

##############################################################################
############################ Assign VM cpu's #################################
##############################################################################
# Summary of the following code:
#  To view current VM instances info
#   virsh list
#  To view current VM cpu's
#   virsh vcpupin <VM_instance_name> <VCPU>
#  To set current VM cpu's
#   virsh vcpupin <VM_instance_name> <VCPU> <CPU>
##############################################################################
echo 
echo "Verifying VM CPU's affinity"
assign_new_values=0
VM_list=($(virsh list | grep running | sed 's/^\s*//g' | sed 's/\s\s*/,/g'))
for VM_curr in ${VM_list[@]}
do
    VM_det=($(echo $VM_curr| sed 's/,/ /g' ))
    VM_instance_name=${VM_det[1]}
    VM_curr_cpu_det_list=($(virsh vcpupin $VM_instance_name | sed 1,2d | sed "s/:\s*/c/g"))
    for VM_curr_cpu_det in ${VM_curr_cpu_det_list[@]}
    do
        VM_curr_cpu_det=($(echo $VM_curr_cpu_det | sed "s/c/ /g"))
        VM_curr_vcpu_index=${VM_curr_cpu_det[0]}
        VM_curr_cpu_list=($(echo ${VM_curr_cpu_det[1]} | perl -pe 's/(\d+)-(\d+)/join(",",$1..$2)/eg' | sed 's/,/ /g'))
        if [ ${#VM_curr_cpu_list[@]} != 1 ]
        then
            assign_new_values=1
            echo "CPU's assigned to VM <> 1"
        elif [ $(echo ${cpu_list[@]:cpu_counter} | grep '\b'$VM_curr_cpu_list'\b' | wc -l) == 0 ]
        then
            assign_new_values=1
            echo "VM CPU not in correct range, can cause poor performance"
        else
            echo "Detected correct CPU assignment - Name:"$VM_instance_name" VCPU:"$VM_curr_vcpu_index" CPU:"$VM_curr_cpu_list
            cpu_list=($(echo ${cpu_list[@]} | sed 's/\b'$VM_curr_cpu_list'\b/ /g' ))
            cpu_list=($(echo ${cpu_list[@]} | sed 's/^/'$VM_curr_cpu_list' /g' ))
            cpu_counter=$(($cpu_counter+1))
        fi
        if [ $assign_new_values == 1 ]
        then
            tmp_cpu=${cpu_list[$cpu_counter]}
            echo "Assign CPU "$tmp_cpu" to VCPU "$VM_curr_vcpu_index
            while true; do
                read -p "Continue? " ans
                case $ans in
                    [Yy]* ) 
                        virsh vcpupin $VM_instance_name $VM_curr_vcpu_index $tmp_cpu
                        cpu_counter=$(($cpu_counter+1))
                        break;;
                    [Nn]* ) 
                        break;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
        fi
    done
done
##############################################################################

##############################################################################
########################## Attach interface cpu's ############################
##############################################################################
#VM_list=($(virsh list | grep running | sed 's/^\s*//g' | sed 's/\s\s*/,/g'))
#for VM_curr in ${VM_list[@]}
#do
#    VM_det=($(echo $VM_curr| sed 's/,/ /g' ))
#    VM_instance_name=${VM_det[1]}
#    virsh domiflist $VM_instance_name | grep -q "vnet0" || virsh attach-interface --domain $VM_instance_name --type network --source default --model virtio --config --live
#done
##############################################################################

echo "Setup_control_node_script_complete"
