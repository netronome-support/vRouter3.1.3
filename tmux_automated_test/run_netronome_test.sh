#!/bin/bash
##############################################################################
#### Different compute node VM to VM test iperf and dpdk test ################
##############################################################################

##############################################################################
############################ run_netronome_test.sh ###########################
# A test used to measure the performance between two VM's. The first Vm 
#  should be located on the current node and the second on a different node.
# This file is the executable for the test. It automates the complete test
#  with the general help of a tmux session.
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

#~~~~~~~~~~~~~~~~~~~~~~~~~ Test constants ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SESSIONNAME="test-session"      #Tmux session name
WINDOWNAME="Main"               #Main window name
CLIENT_IP=10.75.10.25           #Client VM IP as seen from compute node
SERVER_IP=10.75.10.29           #Server VM IP as seen from compute node
CLIENT_NODE_IP=172.16.0.104       #Compute node which server VM is located
SERVER_NODE_IP=172.16.0.109       #Compute node which server VM is located
LINK_SIZE=20                    #Link size e.g. 40Gbits/s
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Driver state tracking. 
# -1: Unknown state
#  0: Virtio-pci driver attached
#  1: igb_uio driver attached
DRIVER_STATE=-1

DIRECTION_STRING_LIST=("s->c" "s<-c" "s<->c")

#######################################################################
###################### Function definitions ###########################
#######################################################################
#Description:
# Executes a cmd each second for specified seconds. Exits 
#  early if a certain string was found in the output.
#Parameters:
# $1 Cmd to execute
# $2 Expected output
# $3 Specified time to wait before timeout
function wait_text {
  timeout $3 bash <<EOT
  while :; do
    sleep 1
    echo '$1' | sh | grep $2 2>&1 > /dev/null && break
  done
EOT
}

#Description:
# Attaches the igb_uio drivers to the interfaces if they
#  are not yet attached
#Globals:
# $DRIVER_STATE - Driver state tracking
function setup_dpdk {
    if [ $DRIVER_STATE != 1 ]
    then
        echo "Setting up interfaces on VM's"
        tmux_send_pane 2 ./install_igb_uio.sh
        tmux_send_pane 3 ./install_igb_uio.sh
        sleep 5
        DRIVER_STATE=1
    fi
}

#Description:
# Attaches the virtio-pci drivers to the interfaces if 
# they are not yet attached
#Globals:
# $DRIVER_STATE - Driver state tracking
function setup_iperf {
    if [ $DRIVER_STATE != 0 ]
    then
        echo "Setting up interfaces on VM's"
        tmux_send_pane 2 ./install_virtio_pci.sh
        tmux_send_pane 3 ./install_virtio_pci.sh
        sleep 5
        DRIVER_STATE=0
    fi
}

#Description:
# Sends a cmd string to the specified pane in the main window
#Parameters:
# $1     : Pane number
# ${@:2} : Cmd string intended to be executed on pane
function tmux_send_pane {
    pane_nr=$1
    parameters="\""${@:2}"\""
    echo tmux send-keys -t $SESSIONNAME":0."$pane_nr $parameters C-m | sh
}

#Description:
# Sends a cmd string to the specified window in the tmux session
#Parameters:
# $1     : Window number/name
# ${@:2} : Cmd string intended to be executed on window
function tmux_send_window {
    window_nr=$1
    parameters="\""${@:2}"\""
    echo tmux send-keys -t $window_nr".0" $parameters C-m | sh
}

#Description:
# Executes the Iperf test between the server and client with one network
function test_iperf_1_instance {
    setup_iperf
    tmux_send_pane 2 iperf3 -s -B 10.0.2.62 -A 1
    tmux_send_pane 3 iperf3 -c 10.0.2.62 -A 1 -Z
    wait_text 'tmux capture-pane -t 0.3 ; tmux show-buffer' '^iperf' 300
    tmux send-keys -t $SESSIONNAME":0.2" C-c
}


function calculate_


function find_dpdk_no_drop_rate{
    tmux capture-pane -t "Server_pktgen".0 
    server_rx=$(tmux show-buffer | grep "rx")
    server_tx=$(tmux show-buffer | grep "tx")
    
    tmux capture-pane -t "Client_pktgen".0 
    client_rx=$(tmux show-buffer | grep "rx")
    client_tx=$(tmux show-buffer | grep "tx")
    
}


#Description:
# Executes a DPDK test with the specified parameters
#Parameters:
# $1 Packet size        [64-9000]
# $2 Packet rate        [1-100]
# $3 Direction          [1(server -> client)/2(server <- client)/3(server <-> client)]
# $4 Traffic type       [udp/tcp]
function test_dpdk_pcktgen {
    pktsize=$1
    pktrate=$2
    direction=$3
    trafficType=$4
    echo "Setting up drivers for dpdk testing"
    setup_dpdk

    tmux resize-pane -t 0.0 -Z
    echo "Starting pktgen on the virtual machines"

    # Start packetgen instances with predefined system variables 
    tmux_send_window "Server_pktgen" ./run_pktgen.sh
    tmux_send_window "Client_pktgen" ./run_pktgen.sh

    # Start vif to monitor drops in window 3 & 4
    tmux_send_window "Server_vif" vif --list --rate
    tmux_send_window "Client_vif" vif --list --rate
    sleep 3

    # Load pktgen with traffic header info (ip's, mac's, ports etc.)
    echo "Loading pktgen with header info"
    tmux_send_window "Server_pktgen" load /root/load_pps
    tmux_send_window "Client_pktgen" load /root/load_pps
    sleep 6

    # Set packet size for test
    echo "Loading Test specific constants - packet size:"$pktsize" rate:"$pktrate" Direction:"${DIRECTION_STRING_LIST[$direction-1]}" Traffic type:"$trafficType
    [ $(($direction & 1)) == 0 ] || tmux_send_window "Server_pktgen" set all size $pktsize
    [ $(($direction & 2)) == 0 ] || tmux_send_window "Client_pktgen" set all size $pktsize

    # Set packet rate for test
    #[ $(($direction & 1)) == 0 ] || tmux_send_window "Server_pktgen" set all rate $pktrate
    #[ $(($direction & 2)) == 0 ] || tmux_send_window "Client_pktgen" set all rate $pktrate
    
    # Set traffic type for test
    [ $(($direction & 1)) == 0 ] || tmux_send_window "Server_pktgen" proto $trafficType all 
    [ $(($direction & 2)) == 0 ] || tmux_send_window "Client_pktgen" proto $trafficType all 

    # Start test and clear all previous stats
    echo "Starting test"
    [ $(($direction & 1)) == 0 ] || tmux_send_window "Server_pktgen" start all
    [ $(($direction & 2)) == 0 ] || tmux_send_window "Client_pktgen" start all
    [ $(($direction & 1)) == 0 ] || tmux_send_window "Server_pktgen" clear all
    [ $(($direction & 2)) == 0 ] || tmux_send_window "Client_pktgen" clear all

    # Wait loop with option to stop test. Also displays info on how to navigate windows.
    echo 
    echo "Test setup complete and started"
    echo
    while :; do
        echo "Use Ctrl-b,<window_nr> to switch between stats"
        echo "Window 0) Main window (This window)"
        echo "Window 1) Server pktgen stats"
        echo "Window 2) Client pktgen stats"
        echo "Window 3) Server vif stats"
        echo "Window 4) Server vif stats"
        echo
        echo "Enter 's' to stop the test and return to previous menu"
        read -p "Enter choice: " OPT
        case "$OPT" in
        s)  echo  "Stopping test"
            break
            ;;
        *) echo "Not a valid option, try again."
           ;;
        esac
    done

    # Stop the test
    [ $(($direction & 1)) == 0 ] || tmux_send_window "Server_pktgen" stop all
    [ $(($direction & 2)) == 0 ] || tmux_send_window "Client_pktgen" stop all

    # Quit pktgen
    tmux_send_window "Server_pktgen" quit
    tmux_send_window "Client_pktgen" quit

    # Quit vif
    tmux_send_window "Server_vif" q
    tmux_send_window "Client_vif" q

    # Clear windows
    tmux_send_window "Server_pktgen" clear
    tmux_send_window "Client_pktgen" clear
    tmux_send_window "Server_vif" clear
    tmux_send_window "Client_vif" clear

    # Zoom out to original view with all four panes.
    tmux select-pane -t 0
}


#Description:
# Executes a user defined pktgen test
function test_dpdk_pcktgen_custom {

    # Define packet size
    while :; do
        read -p "Enter packet size [64-9000]: " OPT
        case "$OPT" in
        6[4-9] | [7-9][0-9] | [0-9][0-9][0-9] | [0-8][0-9][0-9][0-9] | 9000) echo  "Packet size: "$OPT
            pktsize=$OPT
            break
            ;;
        *) echo "Not a valid option, try again."
           ;;
        esac
    done

    # Define packet rate
    while :; do
        read -p "Enter packet rate [1-100]: " OPT
        case "$OPT" in
        [1-9] | [1-9][0-9] | 100) echo  "Packet rate: "$OPT
            pktrate=$OPT
            break
            ;;
        *) echo "Not a valid option, try again."
           ;;
        esac
    done

    # Define direction
    while :; do
        read -p "Enter direction [1(s->c)/2(s<-c)/3(s<->c)]: " OPT
        case "$OPT" in
        [1-3]) echo  "Direction: "${DIRECTION_STRING_LIST[$OPT-1]}
            direction=$OPT
            break
            ;;
        *) echo "Not a valid option, try again."
           ;;
        esac
    done

    # Define traffic type
    while :; do
        read -p "Enter Traffic type [udp/tcp]: " OPT
        case "$OPT" in
        udp | tcp) echo  "Traffic type: "$OPT
            trafficType=$OPT
            break
            ;;
        *) echo "Not a valid option, try again."
           ;;
        esac
    done
    
    test_dpdk_pcktgen $pktsize $pktrate $direction $trafficType
}


#######################################################################
######################### Main function ###############################
#######################################################################

# Check if TMUX variable is defined.
if [ -z "$TMUX" ]
then # $TMUX is empty, create/enter tmux session.
    tmux has-session -t $SESSIONNAME &> /dev/null
    if [ $? != 0 ]
    then
        # create session, window 0, and detach
        echo "Creating  new session"
        tmux new-session -s $SESSIONNAME -d
        tmux rename-window -t $SESSIONNAME':0' $WINDOWNAME
        # configure window
        tmux select-window -t $SESSIONNAME':0'
    fi
    tmux_send_pane 0 ./run_netronome_test.sh
    tmux a -t $SESSIONNAME 
else # else $TMUX is not empty, start test.

    # Recreate all panes
    if [ $(tmux list-panes | wc -l) -gt 1 ] 
    then
        tmux kill-pane -a -t $SESSIONNAME":0.0"
    fi
    tmux split-window -h
    tmux split-window -v
    tmux split-window -v -t 0

    # Check if windows exist and if not, create them
    tmux list-windows | grep -q "Server_pktgen" || tmux new-window -n "Server_pktgen"
    tmux list-windows | grep -q "Client_pktgen" || tmux new-window -n "Client_pktgen"
    tmux list-windows | grep -q "Server_vif" || tmux new-window -n "Server_vif"
    tmux list-windows | grep -q "Client_vif" || tmux new-window -n "Client_vif"
    tmux select-window -t $WINDOWNAME

    # Login server node
    echo "Logging into srv-dc14-2 on pane 2"
    tmux_send_pane 1 clear
    tmux_send_pane 1 ssh "heat-admin@"$SERVER_NODE_IP
    sleep 2
    
    echo "Logging into srv-dc14-2 on pane 3"
    tmux_send_pane 2 clear
    tmux_send_pane 2 ssh "heat-admin@"$SERVER_NODE_IP
    sleep 2
    
    echo "Logging into srv-dc14-2 on pane 3"
    tmux_send_pane 3 clear
    tmux_send_pane 3 ssh "heat-admin@"$CLIENT_NODE_IP
    sleep 2

    tmux select-pane -t 2
    tmux_send_pane 2 ./setup_control_node.sh 
    wait_text 'tmux capture-pane -t 0.2 ; tmux show-buffer' '^Setup_control_node_script_complete' 300
    tmux select-pane -t 3
    tmux_send_pane 3 ./setup_control_node.sh
    wait_text 'tmux capture-pane -t 0.3 ; tmux show-buffer' '^Setup_control_node_script_complete' 300

    # Log into VM's using management interface
    echo "Logging into different VM's"
    tmux_send_pane 2 ssh "root@"$SERVER_IP
    tmux_send_pane 3 ssh "root@"$CLIENT_IP
    sleep 2

    # Alocate IP's to new interfaces.
    #tmux_send_pane 2 ifconfig -a \| grep 52:54: \| cut -d \'\ \' -f 1 \| awk \'\{print \\\"ifconfig \\\"\\\$1\\\" 192.168.122.6 up\\\" \}\' \| sh
    #tmux_send_pane 3 ifconfig -a \| grep 52:54: \| cut -d \'\ \' -f 1 \| awk \'\{print \\\"ifconfig \\\"\\\$1\\\" 192.168.122.5 up\\\" \}\' \| sh
    #tmux_send_pane 2 logout
    #tmux_send_pane 3 logout
    #sleep 2

    # Log into VM's using new alocated IP on 
    echo "Logging into different VM's"
    #tmux_send_pane 2 ssh 192.168.122.6
    #tmux_send_pane 3 ssh 192.168.122.5
    tmux_send_pane 2 ssh "root@"$SERVER_IP
    tmux_send_pane 3 ssh "root@"$CLIENT_IP
    sleep 2

    # Log windows into correct nodes and VM's
    tmux_send_window "Server_pktgen" ssh "heat-admin@"$SERVER_NODE_IP
    tmux_send_window "Server_vif" ssh "heat-admin@"$SERVER_NODE_IP
    sleep 2
    #tmux_send_window "Server_pktgen" ssh 192.168.122.6
    #tmux_send_window "Client_pktgen" ssh 192.168.122.5
    tmux_send_window "Server_pktgen" ssh "root@"$SERVER_IP
    tmux_send_window "Client_pktgen" ssh "root@"$CLIENT_IP
    sleep 2

    # Check and Mount hugepages in VM's
    tmux_send_window "Server_pktgen" grep hugetlbfs /proc/mounts \| grep -q \"pagesize=2M\" \|\| \( mkdir -p /mnt/huge \&\& mount nodev -t hugetlbfs -o rw,pagesize=2M /mnt/huge/ \)
    tmux_send_window "Server_pktgen" echo 2048 \> /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
    tmux_send_window "Client_pktgen" grep hugetlbfs /proc/mounts \| grep -q \"pagesize=2M\" \|\| \( mkdir -p /mnt/huge \&\& mount nodev -t hugetlbfs -o rw,pagesize=2M /mnt/huge/ \)
    tmux_send_window "Client_pktgen" echo 2048 \> /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages

    # Clear all panes and windows
    tmux_send_pane 1 clear
    tmux_send_pane 2 clear
    tmux_send_pane 3 clear
    tmux_send_window "Server_pktgen" clear
    tmux_send_window "Client_pktgen" clear
    echo "Setup complete"
    sleep 1

    #Main while loop - Choose which test to execute
    while :; do
        tmux select-pane -t 0
        clear
        echo "Which test would you like to run:"
        echo "1) Iperf test  - 1 interface"
        echo "2) DPDK-pktgen - Packet size: 64B    Packet rate: 16%    Type: TCP  Direction: Bidirection"
        echo "3) DPDK-pktgen - Packet size: 700B   Packet rate: 94%    Type: TCP  Direction: Bidirection"
        echo "4) DPDK-pktgen - Packet size: 1400B  Packet rate: 94%    Type: TCP  Direction: Bidirection"
        echo "5) DPDK-pktgen - Packet size: 64B    Packet rate: 16%    Type: TCP  Direction: Unidirectional s->c"
        echo "6) DPDK-pktgen - Packet size: 1400B  Packet rate: 94%    Type: TCP  Direction: Unidirectional s->c"
        echo "7) DPDK-pktgen - Packet size: 64B    Packet rate: 16%    Type: UDP  Direction: Bidirection"
        echo "8) DPDK-pktgen - Packet size: 1400B  Packet rate: 94%    Type: UDP  Direction: Bidirection"
        echo "c) DPDK pktgen - Custom parameters"
        echo "x) Exit"
        read -p "Enter choice: " OPT
        tmux_send_pane 2 clear
        tmux_send_pane 3 clear
        case "$OPT" in
        1)  echo "1) Iperf test  - 1 interface"
            test_iperf_1_instance
            ;;
        2)  echo "2) DPDK-pktgen - Packet size: 64B    Packet rate: 16%    Type: TCP  Direction: Bidirection"
            test_dpdk_pcktgen 64 16 3 tcp
            ;;
        3)  echo "3) DPDK-pktgen - Packet size: 700B   Packet rate: 94%    Type: TCP  Direction: Bidirection"
            test_dpdk_pcktgen 700 94 3 tcp
            ;;
        4)  echo "4) DPDK-pktgen - Packet size: 1400B  Packet rate: 94%    Type: TCP  Direction: Bidirection"
            test_dpdk_pcktgen 1400 94 3 tcp
            ;;
        5)  echo "5) DPDK-pktgen - Packet size: 64B    Packet rate: 16%    Type: TCP  Direction: Unidirectional s->c"
            test_dpdk_pcktgen 64 16 1 tcp
            ;;
        6)  echo "6) DPDK-pktgen - Packet size: 1400B  Packet rate: 94%    Type: TCP  Direction: Unidirectional s->c"
            test_dpdk_pcktgen 1400 94 1 tcp
            ;;
        7)  echo "7) DPDK-pktgen - Packet size: 64B    Packet rate: 16%    Type: UDP  Direction: Bidirection"
            test_dpdk_pcktgen 64 16 3 udp
            ;;
        8)  echo "8) DPDK-pktgen - Packet size: 1400B  Packet rate: 94%    Type: UDP  Direction: Bidirection"
            test_dpdk_pcktgen 1400 94 3 udp
            ;;
        c)  echo "c) DPDK pktgen - Custom parameters"
            test_dpdk_pcktgen_custom
            ;;
        x)  echo "x) Exiting script"
            sleep 1
            tmux kill-session -t $SESSIONNAME
            exit 0
            ;;
        *)  echo "Not a valid option, try again."
            ;;
        esac
    done
fi

#######################################################################
#######################################################################
#######################################################################
