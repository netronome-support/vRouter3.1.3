#!/bin/bash
# Cleans the server-manager machine 
dpkg -l | awk '/contrail/ {print $2}' | xargs -Iz dpkg -r z

# On server manager if SMLite was installed, delete all servers
for entry in $(server-manager display server | tail -4 | head -3 | awk '{print $2}'); do echo $entry; server-manager delete server --server_id $entry; done
# Then delete the server manager cluster
server-manager delete cluster --cluster_id <cluster-id>
