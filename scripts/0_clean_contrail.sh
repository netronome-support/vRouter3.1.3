#!/bin/bash
# Removes previous residuals of contrail install on controller/compute nodes
echo "Cleaning contrail"
rm /etc/apt/sources.list.d/*
apt update
apt remove $(dpkg -l | grep -i cloud0 | awk '{print $2}')

