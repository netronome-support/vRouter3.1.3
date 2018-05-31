#!/bin/bash
# Installs dependencies for server-manager
echo "Installing server-manager dependenceies"
apt-get install -y Linux-image-extra-$(uname -r)
apt-get install -y python-nova=2:13.1.4-0ubuntu4.2 libnl-3-200=3.2.27-1 python
apt-get install -y python-minimal=2.7.11-1 libpython-stdlib=2.7.11-1 --allow-downgrades

apt-get install -y libpython-dev=2.7.11-1
apt-get install -y python=2.7.11-1 
apt-get install -y python-dev=2.7.11-1 
echo "Reboot for changes to take effect..."

