#!/bin/bash
# Script to downgrade kernel to Contrail 4.1.1 supported 4.4.0-62
# Download and install kernel files
echo "Downloading files"
mkdir kernelfiles
wget http://security.ubuntu.com/ubuntu/pool/main/l/linux/linux-image-4.4.0-62-generic_4.4.0-62.83_amd64.deb -O kernelfiles/linux-image-4.4.0-62-generic_4.4.0-62.83_amd64.deb
wget http://security.ubuntu.com/ubuntu/pool/main/l/linux/linux-headers-4.4.0-62-generic_4.4.0-62.83_amd64.deb -O kernelfiles/linux-headers-4.4.0-62-generic_4.4.0-62.83_amd64.deb
wget http://security.ubuntu.com/ubuntu/pool/main/l/linux/linux-headers-4.4.0-62_4.4.0-62.83_all.deb -O kernelfiles/linux-headers-4.4.0-62_4.4.0-62.83_all.deb
echo "Installing kernel"
dpkg -i kernelfiles/*.deb

# Update grub configuration
echo "Updating grub"
sed -i '/GRUB_DEFAULT=/c\GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux\4.4.0-62-generic"' /etc/default/grub
sed -i '/GRUB_CMDLINE_LINUX=/c\GRUB_CMDLINE_LINUX="${GRUB_CMDLINE_LINUX_DEFAULT} \intel_iommu=on iommu=pt intremap=on default_hugepagesz=2M \hugepagesz=2M hugepages=8196"' /etc/default/grub
update-grub

# Cleaning up kernel
echo "Removing existing kernel and cleaning up"
# Get existing kernel version
kern=$(uname -r)
# Remove old kernel version
apt-get -y purge linux-headers-$kern linux-image-$kern
# Delete downloaded files
rm -r kernelfiles
# Reboot
read -p "Rebooting now..."
reboot


