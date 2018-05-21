#!/bin/bash
# Install dependencies
echo "Installing dependencies"
apt-get -y install dkms python libjansson4 ethtool
apt autoremove
# Download driver files
echo "Downloading NFP drivers"
#mkdir NFP
wget http://pahome.netronome.com/releases-intern/vrouter/builds/Netronome_R4.1_build_31.tar -O NFP/Netronome_R4.1_build_31.tar

# Extract and install driver package
echo "Installing driver"
tar xvf NFP/Netronome_R4.1_build_*.tar
cd ./NFP/Netronome_R4.1_build_*/repo_setup/debs/
dpkg -i agilio-nfp-driver-dkms_2018.04.13.0400.237fdbb_all.deb\
	 ns-agilio-vrouter-udev_4.1.0.0-*.deb agilio-nic-firmware-2.0.7-1.deb\
	 nfp-bsp-6000-b0_2018.04.13.1600-1_amd64.deb 
apt-get install -f
dpkg -i agilio-nfp-driver-dkms_2018.04.13.0400.237fdbb_all.deb\
	 ns-agilio-vrouter-udev_4.1.0.0-*.deb agilio-nic-firmware-2.0.7-1.deb\
	 #nfp-bsp-6000-b0_2018.04.13.1600-1_amd64.deb 

# Reload NFP drivers
echo "Reloading drivers"
rmmod nfp
modprobe nfp

# Configure drivers to load on startup
echo "Drivers"
/opt/netronome/libexec/write_udev_rules.sh
cat /etc/udev/rules.d/10-netronome.udev.rules
update-initramfs -u

