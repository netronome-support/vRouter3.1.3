from fabric.api import env

#Management addresses of hosts in the cluster
lizard = 'root@172.26.1.126'  # control & compute node - nfp
spock = 'root@172.26.1.127' # compute node - nfp

#External routers if any
#for eg.
#ext_routers = [('mx1', '10.204.216.253')]
ext_routers = []

#Autonomous system number
router_asn = 64525

#Host from which the fab commands are triggered to install and provision
host_build = lizard

#Role definition of the hosts.
env.roledefs = {
    'all': [lizard, spock],
    'cfgm': [lizard],
    'openstack': [lizard],
    'control': [lizard],
    'compute': [spock, lizard],
    'collector': [lizard],
    'webui': [lizard],
    'database': [lizard],
    'build': [host_build],
    'storage-master': [lizard],
    'storage-compute': [spock, lizard],
}

# required if using env.ns_agilio_vrouter
control_data = {
lizard : { 'ip': '172.18.48.32/24',
'gw' : '172.18.48.1',
'device' :'nfp_p0'},
spock : { 'ip': '172.18.48.33/24',
'gw' : '172.18.48.1',
'device' :'nfp_p0'},
}

# Setup Netronome Agilio vRouter on specified nodes
env.ns_agilio_vrouter = {
lizard: {'huge_page_alloc': '12G',
'huge_page_size' : '1G',
'coremask' : '2,4',
'pinning_mode' : 'auto:split'},
spock: {'huge_page_alloc': '12G',
'huge_page_size' : '1G',
'coremask' : '2,4',
'pinning_mode' : 'auto:split'}
}

env.hostnames = {
    lizard: 'lizard',
    spock: 'spock',
}

#Openstack admin password
env.openstack_admin_password = 'netronome'

# Passwords of each host
env.passwords = {
    lizard: 'netronome',
    spock: 'netronome',
    host_build: 'netronome',
}

#For reimage purpose
env.ostypes = {
    lizard: 'ubuntu',
    spock: 'ubuntu',
}

env.enable_lbaas = True