# Netronome vRouter Installation Guide

## Pre-Requisites

* Ubuntu 14.04.3 (3.13.0-100 Errata 47 patched kernel)
* Contrail-Cloud 3.1.3.0-73 (Mitaka)
* Agilio vRouter 3.1.0.0-281
* Minimum number of required hosts: 2

## Remove existing Contrail & Fabric installations
      dpkg -l | awk '/contrail/ {print $2}' | xargs -Iz dpkg -r z

## On all nodes

* Install Ubuntu 14.04.3 on all the nodes in the setup
    
## On Controller node

* Install Java

      apt-get -y --force-yes --allow-unauthenticated install default-jre-headless

* Install BSP dependencies on the computes
```
apt-get install -y make autoconf automake libtool \
gcc g++ bison flex hwloc-nox libreadline-dev libpcap-dev dkms libftdi1 libjansson4 \
libjansson-dev guilt pkg-config libevent-dev ethtool libssl-dev \
libnl-3-200 libnl-3-dev libnl-genl-3-200 libnl-genl-3-dev psmisc gawk \
libzmq3-dev protobuf-c-compiler protobuf-compiler python-protobuf \
libnuma1 libnuma-dev python-six python-ethtool
```

* Download & install Contrail packages

      dpkg -i contrail-install-packages_3.1.*.*_all.deb
      /opt/contrail/contrail_packages/setup.sh
      apt-get update

* Populate testbed with relevant information

      /opt/contrail/utils/fabfile/testbeds/testbed.py

---

### Testbed example files

   [Testbed examples directory](https://github.com/netronome-support/vRouter/tree/master/testbed)

   [2 node testbed](https://raw.githubusercontent.com/netronome-support/vRouter/master/testbed/testbed_2node.py) |
   [2 node(bond interface) testbed](https://raw.githubusercontent.com/netronome-support/vRouter/master/testbed/testbed_2node_bond.py) |
   [3 node testbed](https://raw.githubusercontent.com/netronome-support/vRouter/master/testbed/testbed_3node.py)

---

* Install contrail-install-packages on remaining nodes

      cd /opt/contrail/utils
      fab install_pkg_all:/tmp/contrail-install-packages-x.x.x.x-xxx~openstack_version_all.deb
         
* Confirm installation of Contrail packages

      dpkg -l | grep contrail

* Upgrade all nodes to recommended kernel

      fab upgrade_kernel_all

* Confirm that correct kernel is running

      # uname -r
      3.13.0-106-generic

* Confirm that the required kernel parameters are present

      #cat /proc/cmdline
      BOOT_IMAGE=.. intel_iommu=on iommu=pt intremap=on

>**NOTE:** If the aforementioned parameters are missing it may be necessary to modify GRUB manually:
```
vi /etc/default/grub
#edit the following line:
GRUB_CMDLINE_LINUX="intel_iommu=on iommu=pt intremap=on" 
#apply changes
update-grub
reboot
```

* Install Contrail dependencies on all the computes

      cd /opt/contrail/contrail_install_repo
      dpkg -i libnl-3-200_3.2.21-1ubuntu4_amd64.deb libc6*
      apt-get install nova-compute
      apt-get -f install -y

      wget http://launchpadlibrarian.net/264517293/libexpat1_2.1.0-4ubuntu1.3_amd64.deb
      dpkg -i libexpat1_2.1.0-4ubuntu1.3_amd64.deb

* Install ns-agilio-vrouter-depends-packages

      cd /opt/contrail/utils
      fab install_ns_agilio_nic:/tmp/ns-agilio-vrouter-depends-packages_x.x.x.x-xxx_amd64.deb

* Confirm installation of vRouter packages

      # dpkg -l | grep vrouter
      ns-agilio-vrouter-depends-packages 

* Change the media configuration of the SmartNIC if you are using **breakout cables** (1 X 40GbE(default) -> 4 x 10GbE)
         
         This should create four NFP interfaces: nfp_p0, nfp_p1, nfp_p2, nfp_p3

      modprobe nfp #load nfp.ko driver
      /opt/netronome/bin/nfp-media --set-media=phy0=4x10G
      service ns-core-nic.autorun clean
      reboot

* Install contrail

      fab install_contrail

* Setup control_data interfaces

      fab setup_interface

>**NOTE:** After this step you should have communication on the underlay network - Test by pinging between the interfaces

* Provision the cluster

      fab setup_all

## On all nodes 

* Verify whether deployment was successful

      contrail-status
      /opt/netronome/libexec/nfp-vrouter-status -r





## Contrail-Netronome Architecture
  ![architecture](images/contrail_agilio_architecture.png)

