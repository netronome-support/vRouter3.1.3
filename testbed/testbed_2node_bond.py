from fabric.api import env

#Management addresses of hosts in the cluster
host0 = 'root@172.26.1.126'  # control & compute node - nfp
host1 = 'root@172.26.1.127' # compute node - nfp

#External routers if any
#for eg.
#ext_routers = [('mx1', '10.204.216.253')]
ext_routers = []

#Autonomous system number
router_asn = 64525

#Host from which the fab commands are triggered to install and provision
host_build = host0

#Role definition of the hosts.
env.roledefs = {
    'all': [host0, host1],
    'cfgm': [host0],
    'openstack': [host0],
    'control': [host0],
    'compute': [host0, host1],
    'collector': [host0],
    'webui': [host0],
    'database': [host0],
    'build': [host_build],
    'storage-master': [host0],
    'storage-compute': [host0, host1],
}

# required if using env.ns_agilio_vrouter
control_data = {
host0 : { 'ip': '172.18.48.32/24',
'gw' : '172.18.48.1',
'device':'bond0'},
host1 : { 'ip': '172.18.48.33/24',
'gw' : '172.18.48.1',
'device':'bond0'},
}

bond= {
# 4x10G breakout mode on a 1x40G SmartNIC
host0 : { 'name': 'bond0',
'member' : ['nfp_p0','nfp_p1','nfp_p2','nfp_p3'],
'mode' : '802.3ad',
'xmit_hash_policy' : 'layer3+4' },
host1 : { 'name': 'bond0',
'member' : ['nfp_p0','nfp_p1','nfp_p2','nfp_p3'],
'mode' : '802.3ad',
'xmit_hash_policy' : 'layer3+4' },
}

# Setup Netronome Agilio vRouter on specified nodes
env.ns_agilio_vrouter = {
host0: {'huge_page_alloc': '12G',
'huge_page_size' : '1G',
'coremask' : '2,4',
'pinning_mode' : 'auto:split'},
host1: {'huge_page_alloc': '12G',
'huge_page_size' : '1G',
'coremask' : '2,4',
'pinning_mode' : 'auto:split'}
}

env.hostnames = {
    host0: 'host0',
    host1: 'host1',
}

#Openstack admin password
env.openstack_admin_password = 'netronome'

# Passwords of each host
env.passwords = {
    host0: 'netronome',
    host1: 'netronome',
    host_build: 'netronome',
}

#For reimage purpose
env.ostypes = {
    host0: 'ubuntu',
    host1: 'ubuntu',
}

env.enable_lbaas = True