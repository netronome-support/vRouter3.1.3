from fabric.api import env

#Management addresses of hosts in the cluster
h = 'root@172.26.1.104'          # control & compute node - nfp
d = 'root@172.26.1.105' # compute node - nfp

#External routers if any
#for eg.
#ext_routers = [('mx1', '10.204.216.253')]
ext_routers = []

#Autonomous system number
router_asn = 64525

#Host from which the fab commands are triggered to install and provision
host_build = h

#Role definition of the hosts.
env.roledefs = {
    'all': [h, d],
    'cfgm': [h],
    'openstack': [h],
    'control': [h],
    'compute': [d, h],
    'collector': [h],
    'webui': [h],
    'database': [h],
    'build': [host_build],
    'storage-master': [h],
    'storage-compute': [d, h],
}

# required if using env.ns_agilio_vrouter
control_data = {
h : { 'ip': '172.18.48.32/24',
'gw' : '172.18.48.1',
'device' :'nfp_p0'},
d : { 'ip': '172.18.48.33/24',
'gw' : '172.18.48.1',
'device' :'nfp_p0'},
}

# Setup Netronome Agilio vRouter on specified nodes
env.ns_agilio_vrouter = {
h: {'huge_page_alloc': '24G',
'huge_page_size' : '1G',
'coremask' : '2,4',
'pinning_mode' : 'auto:split'},
d: {'huge_page_alloc': '24G',
'huge_page_size' : '1G',
'coremask' : '2,4',
'pinning_mode' : 'auto:split'}
}

env.hostnames = {
    h: 'h',
    d: 'd',
}

#Openstack admin password
env.openstack_admin_password = 'netronome'

# Passwords of each host
env.passwords = {
    h: 'netronome',
    d: 'netronome',
    host_build: 'netronome',
}

#For reimage purpose
env.ostypes = {
    h: 'ubuntu',
    d: 'ubuntu',
}

env.enable_lbaas = True