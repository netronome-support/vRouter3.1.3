#!/bin/bash
# Script to downgrade kernel to Contrail 4.1.1 supported 4.4.0-62
# Check if kernel needs to change
echo "Checking kernel version"
kern=$(uname -r)
if [[ "$kern" == "4.4.0-62-generic" ]]; then
	echo "Kernel is $kern no need to change"
	exit -1
else
	echo "Changing kernel to 4.4.0-62"
fi

# Download and install kernel files
echo "Downloading files"
mkdir kernelfiles
wget http://security.ubuntu.com/ubuntu/pool/main/l/linux/linux-image-4.4.0-62-generic_4.4.0-62.83_amd64.deb -O kernelfiles/linux-image-4.4.0-62-generic_4.4.0-62.83_amd64.deb
wget http://security.ubuntu.com/ubuntu/pool/main/l/linux/linux-headers-4.4.0-62-generic_4.4.0-62.83_amd64.deb -O kernelfiles/linux-headers-4.4.0-62-generic_4.4.0-62.83_amd64.deb
wget http://security.ubuntu.com/ubuntu/pool/main/l/linux/linux-headers-4.4.0-62_4.4.0-62.83_all.deb -O kernelfiles/linux-headers-4.4.0-62_4.4.0-62.83_all.deb
echo "Installing kernel"
dpkg -i kernelfiles/*.deb

# Cleaning up and removing old kernel
echo "Removing existing kernel and cleaning up"
apt-get -y purge linux-headers-$kern linux-image-$kern

# Delete downloaded files
rm -r kernelfiles

# Update grub configuration
echo "Updating grub"
sed -i '/GRUB_DEFAULT=/c\GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux\4.4.0-62-generic"' /etc/default/grub
sed -i '/GRUB_CMDLINE_LINUX=/c\GRUB_CMDLINE_LINUX="${GRUB_CMDLINE_LINUX_DEFAULT} \intel_iommu=on iommu=pt intremap=on default_hugepagesz=2M \hugepagesz=2M hugepages=8196"' /etc/default/grub
update-grub

# Reboot
echo "Rebooting now..."
reboot


