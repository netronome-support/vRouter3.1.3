from fabric.api import env

#Management addresses of hosts in the cluster
HOST0 = 'root@172.26.1.126'  # control & compute node - nfp
HOST1 = 'root@172.26.1.127' # compute node - nfp

#External routers if any
#for eg.
#ext_routers = [('mx1', '10.204.216.253')]
ext_routers = []

#Autonomous system number
router_asn = 64525

#Host from which the fab commands are triggered to install and provision
host_build = HOST0

#Role definition of the hosts.
env.roledefs = {
    'all': [HOST0, HOST1],
    'cfgm': [HOST0],
    'openstack': [HOST0],
    'control': [HOST0],
    'compute': [HOST1, HOST0],
    'collector': [HOST0],
    'webui': [HOST0],
    'database': [HOST0],
    'build': [host_build],
    'storage-master': [HOST0],
    'storage-compute': [HOST1, HOST0],
}

# required if using env.ns_agilio_vrouter
control_data = {
HOST0 : { 'ip': '172.18.48.32/24',
'gw' : '172.18.48.1',
'device' :'nfp_p0'},
HOST1 : { 'ip': '172.18.48.33/24',
'gw' : '172.18.48.1',
'device' :'nfp_p0'},
}

# Setup Netronome Agilio vRouter on specified nodes
env.ns_agilio_vrouter = {
HOST0: {'huge_page_alloc': '12G',
'huge_page_size' : '1G',
'coremask' : '2,4',
'pinning_mode' : 'auto:split'},
HOST1: {'huge_page_alloc': '12G',
'huge_page_size' : '1G',
'coremask' : '2,4',
'pinning_mode' : 'auto:split'}
}

env.hostnames = {
    HOST0: 'HOST0',
    HOST1: 'HOST1',
}

#Openstack admin password
env.openstack_admin_password = 'netronome'

# Passwords of each host
env.passwords = {
    HOST0: 'netronome',
    HOST1: 'netronome',
    host_build: 'netronome',
}

#For reimage purpose
env.ostypes = {
    HOST0: 'ubuntu',
    HOST1: 'ubuntu',
}

env.enable_lbaas = True