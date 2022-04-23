#!/bin/bash

script_dir=$(dirname $0)
source ${script_dir}/func/first-boot-func.sh
source ${script_dir}/envs.sh

if [[ ${NODE} != 'jenkins-ci' ]]
then
	exit
fi

set_ci_hostname

randomize_root_password

# disable_firewalld

update_iptable_settings

disable_swap

# disable_selinux

disable_wifi_adapter

update_cgroup_memory_settings

cleanup

expand_filesystem

shutdown -r now

