#!/bin/bash 
# Script to install SMLink on Orchestrator
# Download package
echo "Downloading contrail package"
#wget http://172.26.1.131/nas/vrouter4/contrail-server-manager-installer_4.1.0.0-8~xenial.deb
wget http://bonobo.netronome.com/vrouter/dependencies/juniper_packages/contrail-server-manager-installer_4.1.0.0-8~xenial.deb
# Install package
echo "Installing contrail Server-Manager"
dpkg -i contrail-server-manager-installer_4.1.0.0-8~xenial.deb

# Start contrail setup and watch it's deployment
echo "Starting contrail install"
/opt/contrail/contrail_server_manager/setup.sh --all --smlite --hostip=172.26.1.53

tail -f `find /var/log/contrail/install_logs | sort -r | head -1`
# Restart contrail service
echo "Restarting contrail"
service contrail-server-manager restart
echo "Cleaning up"
rm -r contrail-server-manager-nstaller_4.1.0.0-8~xenial.deb
