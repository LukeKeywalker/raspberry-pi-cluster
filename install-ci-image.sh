####################################################
# script for provisioning an sd card with CentOS 7 #
# Jenkins 2 CI host operating system               #
####################################################

#!/bin/bash

image_file=$1
rsa_pub_key=$2

image_mountpoint='/mnt/centos'
image_root_partition='/dev/mmcblk0p2'
image_device='/dev/mmcblk0'

script_dir=$(dirname $0)

banner() 
{
	echo "Jenkins 2 host os image installer"
}


print_usage() 
{
	echo "usage: $0 image_file rsa_public_key" 
}

parse_arguments() 
{
	if [ -z "${image_file}" ] || [[ ! -f ${image_file} ]]
	then
		print_usage
		exit 1
	fi

	if [ -z "${rsa_pub_key}" ] || [[ ! -f ${rsa_pub_key} ]]
	then
		print_usage
		exit 1
	fi
}

mount_image() 
{
	# create mountpoint if does not exist
	# and mount image card
	echo "mounting node's os image at ${image_mountpoint}"

	mkdir -p ${image_mountpoint} 
	mount ${image_root_partition} ${image_mountpoint}
}

unmount_image() 
{
	# flush card writes before unmounting
	sync

	# unmount image card
	umount ${image_root_partition}
}

copy_image() 
{
	# copy base os image to sd card
	# assume card reader being /dev/mmcblk0
	echo "copying ${image_file} to ${image_device} device"

	xzcat ${image_file} | pv | dd bs=4M of=${image_device}
	sync
}

install_first_run_script() 
{
	# copy current user's id_rsa.pub public key for ssh access
	echo "copying public RSA key"
	mkdir -p ${image_mountpoint}/root/.ssh
	cp ${rsa_pub_key} ${image_mountpoint}/root/.ssh/authorized_keys

	# copy hardened sshd configuration
	echo "copying hardened sshd configuration"
	cp config/sshd_config ${image_mountpoint}/etc/ssh/sshd_config
	
	# copy first run configuration script to
	# the root folder, it will be picked up from
	# there on the first boot by the cron job.
	# first-boot.sh script will then remove itself
	# from crontab and disk after running
	echo "installing first run script"
	first_boot_dir=${image_mountpoint}/root/first-boot/
	cp -r ${script_dir}/first-boot/ ${first_boot_dir}

	# those envs will be used to let node know if it's
	# master or worker node in order to select appropriate
	# setup steps during the first boot
	echo "configuring setup environment variables"
	envs=${first_boot_dir}/envs.sh
	echo "export NODE='jenkins-ci'" > ${envs}

	# define first boot cron job
	echo "setting up first run cron job"
	echo "@reboot root /bin/bash /root/first-boot/setup-ci.sh" >> ${image_mountpoint}/etc/crontab
}

install_image() 
{
	copy_image

	if [ $? -ne 0 ]; then exit; fi

	mount_image

	if [ $? -ne 0 ]; then exit; fi

	install_first_run_script

	if [ $? -ne 0 ]; then exit; fi

	unmount_image

	echo "Jenkins 2 CI host os image installed successfully"
}

insert_card_prompt()
{
	read -p "Insert sd card press [RETURN] to continue..."
}

parse_arguments

banner

insert_card_prompt

install_image

