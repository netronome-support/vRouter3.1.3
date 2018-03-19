# Netronome vRouter Installation Guide

## Pre-Requisites

* Ubuntu 14.04.3/4 (3.13.0-100 Errata 47 patched kernel)
* Contrail-Cloud 3.1.3.0-73 (Mitaka)
* Agilio vRouter 3.1.0.0-281
* Minimum number of required hosts: 2

## Remove existing Contrail & Fabric installations
      dpkg -l | awk '/contrail/ {print $2}' | xargs -Iz dpkg -r z

## On all nodes

* Install Ubuntu 14.04.3/4 on all the nodes in the setup
    
## On Controller node

>**NOTE:** The following commands must be executed on the Controller node if not specifically stated otherwise.

* Install Java

      apt-get -y --force-yes --allow-unauthenticated install default-jre-headless

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

* Install Contrail packages on remaining nodes

      cd /opt/contrail/utils
      fab install_pkg_all:/tmp/contrail-install-packages-x.x.x.x-xxx~openstack_version_all.deb
         
* Confirm installation of Contrail packages

      # dpkg -l | grep contrail
      contrail-install-packages

* Upgrade all nodes to recommended kernel

      fab upgrade_kernel_all

* Confirm that correct kernel is running

      # uname -r
      3.13.0-106-generic

* Confirm that the required kernel parameters are present **on all the nodes in the cluster**

      #cat /proc/cmdline
      BOOT_IMAGE=.. intel_iommu=on iommu=pt intremap=on

>**NOTE:** If the aforementioned parameters are **missing** from the output modify GRUB manually:
```
vi /etc/default/grub
#edit the following line:
sed -i '/GRUB_CMDLINE_LINUX=/c\GRUB_CMDLINE_LINUX="intel_iommu=on iommu=pt intremap=on"' /etc/default/grub
#apply changes
update-grub
#confirm changes
grep iommu /boot/grub/grub.cfg
#reboot
reboot
```

* Install Contrail dependencies by running the commands below **on all the computes**

        cd /opt/contrail/contrail_install_repo
        dpkg -i libnl-3-200_3.2.21-1ubuntu4_amd64.deb libc6*

        wget http://launchpadlibrarian.net/264517293/libexpat1_2.1.0-4ubuntu1.3_amd64.deb
        dpkg -i libexpat1_2.1.0-4ubuntu1.3_amd64.deb

        apt-get install nova-compute
        apt-get -f install -y

* Install ns-agilio-vrouter-depends-packages

      cd /opt/contrail/utils
      fab install_ns_agilio_nic:/tmp/ns-agilio-vrouter-depends-packages_x.x.x.x-xxx_amd64.deb

* Confirm installation of vRouter packages

      # dpkg -l | grep vrouter
      ns-agilio-vrouter-depends-packages 

* Change the media configuration of the SmartNIC if you are using **breakout cables** (1 X 40GbE(default) -> 4 x 10GbE)
         
         This should create four NFP interfaces: nfp_p0, nfp_p1, nfp_p2, nfp_p3

      modprobe nfp #load nfp.ko driver
      /opt/netronome/bin/nfp-media phy0=4x10G
      service ns-core-nic.autorun clean
      reboot


* Install Contrail

>**NOTE:** Confirm presence of ```"127.0.0.1 $hostname"``` in **/etc/hosts** where ```hostname=`cat /etc/hostname` ```

      cd /opt/contrail/utils
      fab install_contrail

* Setup control_data interfaces

      fab setup_interface

>**NOTE:** After this step you should have communication on the underlay network - Test by pinging between the interfaces

* Provision the cluster

      fab setup_all

## On all nodes 

* Verify whether deployment was successful

**Contrail status**

```
contrail-status

== Contrail vRouter ==
supervisor-vrouter:           active
contrail-vrouter-agent        active
contrail-vrouter-nodemgr      active

== Contrail Control ==
supervisor-control:           active
contrail-control              active
contrail-control-nodemgr      active
contrail-dns                  active
contrail-named                active

== Contrail Analytics ==
supervisor-analytics:         active
contrail-alarm-gen            active
contrail-analytics-api        active
contrail-analytics-nodemgr    active
contrail-collector            active
contrail-query-engine         active
contrail-snmp-collector       active
contrail-topology             active

== Contrail Config ==
supervisor-config:            active
contrail-api:0                active
contrail-config-nodemgr       active
contrail-device-manager       active
contrail-discovery:0          active
contrail-schema               active
contrail-svc-monitor          active
ifmap                         active

== Contrail Web UI ==
supervisor-webui:             active
contrail-webui                active
contrail-webui-middleware     active

== Contrail Database ==
contrail-database:            active

== Contrail Supervisor Database ==
supervisor-database:          active
contrail-database-nodemgr     active
kafka                         active

== Contrail Support Services ==
supervisor-support-service:   active
rabbitmq-server               active
```

**vRouter status**

```
vrouter_troubleshoot.sh -R

===[ TROUBLESHOOT ItemName:     nfp_vrouter_status ]===
===[ TROUBLESHOOT Description:  Agilio vRouter health ]===

======================[ Agilio vRouter Health Report ]======================
Version info:
------------------
nfp_vrouter module rev:                      ... 00feda2e055904f48e0ed8c98cb53fd05a4671d2
Firmware rev:                                ... 00feda2e055904f48e0ed8c98cb53fd05a4671d2
Firmware flowenv rev:                        ... 1523449544e7
Firmware global reorder rev:                 ... 25c868a8c724
Firmware NFD rev:                            ... 7513c6c11c9b

Agilio vRouter Health Report:
------------------
NFP: Card Detected                           ... [PASS]
NFP: Firmware Loaded                         ... [PASS]
NFP: Control Message Channel Responsive      ... [PASS]
NFP: Ingress NBI Backed Up                   ... [PASS]
NFP: Parity Errors                           ... [PASS]
Kernel Module: nfp                           ... [PASS]
Kernel Module: nfp_vrouter                   ... [PASS]
Kernel Module: vrouter                       ... [PASS]
Userspace Process: virtiorelayd              ... [PASS]

Overall System State     [PASS]

```







## Contrail-Netronome Architecture
  ![architecture](images/contrail_agilio_architecture.png)

