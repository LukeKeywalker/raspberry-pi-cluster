#!/bin/bash

script_dir=$(dirname $0)
source ${script_dir}/func/first-boot-func.sh
source ${script_dir}/envs.sh

# check if setup is executed for master or 
# worker node and set hostname and firewall
# rules accordingly                       
if [[ ${NODE} -le ${NUM_MASTER_NODES} ]]
then
	 add_master_node_firewall_rules
	 set_master_node_hostname ${NODE}
else
	 add_worker_node_firewall_rules
	 set_worker_node_hostname $((${NODE}-${NUM_MASTER_NODES}))
fi

# steps common for both master and worker nodes #
randomize_root_password

# disable_firewalld

update_iptable_settings

disable_swap

# disable_selinux

disable_wifi_adapter

update_cgroup_memory_settings

add_hosts ${NUM_MASTER_NODES} ${NUM_WORKER_NODES}

cleanup

expand_filesystem

mount_data_storage

shutdown -r now

