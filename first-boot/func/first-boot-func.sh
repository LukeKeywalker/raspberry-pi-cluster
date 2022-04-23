#!/bin/bash

export err_log='/tmp/first-boot-err.log'

cleanup()
{
	# store temporary crontab file without first-boot entry
	/bin/cat /etc/crontab | /bin/grep -v 'first-boot' > /etc/crontab.tmp

	# remove current crontab file
	/bin/rm -f /etc/crontab

	# restore crontab file without first boot entry
	/bin/mv -f /etc/crontab.tmp /etc/crontab

	# remove first boot scripts
	rm -rf /root/first-boot/
}

expand_filesystem()
{
	rootfs-expand
}

random_password()
{
	< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;
}

randomize_root_password()
{
	echo "root:$(random_password)" | chpasswd
}

add_master_node_firewall_rules()
{

	firewall-cmd --permanent --add-port=6443/tcp
	firewall-cmd --permanent --add-port=2379-2380/tcp
	firewall-cmd --permanent --add-port=10250/tcp
	firewall-cmd --permanent --add-port=10251/tcp
	firewall-cmd --permanent --add-port=10252/tcp
	firewall-cmd --permanent --add-port=10255/tcp

	# not sure why, it always needed to be done again
	# after nodes were up
	firewall-cmd --permanent --add-port=6443/tcp

	firewall-cmd --reload
}

add_worker_node_firewall_rules()
{
	firewall-cmd --permanent --add-port=10251/tcp
	firewall-cmd --permanent --add-port=10255/tcp
	firewall-cmd --reload
}

update_iptable_settings()
{
	echo 'net.bridge.bridge-nf-call-ip6tables = 1' > /etc/sysctl.d/k8s.conf
	echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.d/k8s.conf
	sysctl --system
}

disable_swap()
{
	sed -i '/swap/d' /etc/fstab
	swapoff -a
}

disable_selinux()
{
	setenforce 0
	sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
}

disable_firewalld()
{
	systemctl disable firewalld --now
}

disable_wifi_adapter() 
{
	apt install network-manager -y
	nmcli radio wifi off
}

update_cgroup_memory_settings()
{
        # attach to the end of the line with sed and
        # store result in temporary file
        sed '$s/$/ cgroup_memory=1 cgroup_enable=memory/' /boot/firmware/cmdline.txt > cmdline.tmp

        # move file with attached cgroup settings back
        # to /boot/cmdline.txt
        mv -f cmdline.tmp /boot/firmware/cmdline.txt
}

set_master_node_hostname()
{
	hostnamectl set-hostname master-${1}
}

set_worker_node_hostname()
{
	hostnamectl set-hostname worker-${1}
}

add_hosts()
{
	num_master_nodes=${1}
	num_worker_nodes=${2}

	add_master_nodes_hosts ${num_master_nodes}
	add_worker_nodes_hosts ${num_master_nodes} ${num_worker_nodes}
}

set_ci_hostname()
{
	hostnamectl set-hostname jenkins-ci
}

add_master_nodes_hosts()
{
	# assumes that all cluster nodes have static ips
	# assigned in range 192.168.1.11-19
	num_master_nodes=${1}

	for (( i=1; i<=${num_master_nodes}; i++ ))
	do
		echo "192.168.1.1${i}	master-${i}.k3s.local	master-${i}" >> /etc/hosts
	done
}

add_worker_nodes_hosts()
{
	# assumes that all cluster nodes have static ips
	# assigned in range 192.168.1.11-19
	num_master_nodes=${1}
	num_worker_nodes=${2}
	
	for (( i=1; i<=${num_worker_nodes}; i++ ))
	do
		echo "192.168.1.1$((${i}+${num_master_nodes}))	worker-${i}.k3s.local	worker-${i}" >> /etc/hosts
	done
}

mount_data_storage()
{
	storage_uuid=$(blkid | grep /dev/sda1 | awk '{ print $2 }')
	if [ "$storage_uuid" != "" ]
	then
		mkdir -p /data
		echo $storage_uuid /data ext4 defaults 0 2 >> /etc/fstab
	fi
}
