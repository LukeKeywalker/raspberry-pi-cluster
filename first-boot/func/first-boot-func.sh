#!/bin/bash

export err_log='/tmp/first-boot-err.log'

cleanup()
{
	# store temporary crontab file without first-boot entry
	/bin/cat /etc/crontab | /bin/grep -v 'first-boot' > /etc/crontab.tmp

	# remove current crontab file
	/bin/rm -f /etc/crontab

	# restore crontab file without first boot entry
	/bin/mv /etc/crontab.tmp /etc/crontab

	# remove first boot scripts
	rm -rf /root/first-boot/
}

expand_filesystem()
{
	rootfs-expand
}

create_user()
{
	useradd --create-home\
		--groups wheel\
		--shell /bin/bash\
		$1
	echo "$1:qwert" | chpasswd
}

add_master_node_firewall_rules()
{
	firewall-cmd --permanent --add-port=6443/tcp
	firewall-cmd --permanent --add-port=2379-2380/tcp
	firewall-cmd --permanent --add-port=10250/tcp
	firewall-cmd --permanent --add-port=10251/tcp
	firewall-cmd --permanent --add-port=10252/tcp
	firewall-cmd --permanent --add-port=10255/tcp
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

update_cgroup_memory_settings()
{
	sed '$s/$/ cgroup_memory=1 cgroup_enable=memory/' /boot/cmdline.txt > cmdline.tmp
	mv cmdline.tmp /boot/cmdline.txt
}

set_master_node_hostname()
{
	hostnamectl set-hostname master-node-$1
}

set_worker_node_hostname()
{
	hostnamectl set-hostname worker-node-$1
}

add_worker_nodes_hosts()
{
}
