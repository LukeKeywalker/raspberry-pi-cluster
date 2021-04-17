#!/bin/bash

image_file=$1
num_nodes=$2

image_mountpoint='/mnt/centos'
image_root_partition='/dev/mmcblk0p3'
image_device='/dev/mmcblk0'

script_dir=$(dirname $0)

banner() 
{
	echo '█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗'
	echo '╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝'
	echo '                                                                                                                  '
	echo '                                                                                                                  '
	echo '                                                                                                                  '
	echo '                             ██████╗██╗     ██╗   ██╗███████╗████████╗███████╗██████╗                             '
	echo '▄ ██╗▄▄ ██╗▄▄ ██╗▄▄ ██╗▄    ██╔════╝██║     ██║   ██║██╔════╝╚══██╔══╝██╔════╝██╔══██╗    ▄ ██╗▄▄ ██╗▄▄ ██╗▄▄ ██╗▄'
	echo ' ████╗ ████╗ ████╗ ████╗    ██║     ██║     ██║   ██║███████╗   ██║   █████╗  ██████╔╝     ████╗ ████╗ ████╗ ████╗'
	echo '▀╚██╔▀▀╚██╔▀▀╚██╔▀▀╚██╔▀    ██║     ██║     ██║   ██║╚════██║   ██║   ██╔══╝  ██╔══██╗    ▀╚██╔▀▀╚██╔▀▀╚██╔▀▀╚██╔▀'
	echo '  ╚═╝   ╚═╝   ╚═╝   ╚═╝     ╚██████╗███████╗╚██████╔╝███████║   ██║   ███████╗██║  ██║      ╚═╝   ╚═╝   ╚═╝   ╚═╝ '
	echo '                             ╚═════╝╚══════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝                            '
	echo '                                                                                                                  '
	echo '██╗███╗   ███╗ █████╗  ██████╗ ███████╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     ███████╗██████╗  '
	echo '██║████╗ ████║██╔══██╗██╔════╝ ██╔════╝    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔════╝██╔══██╗ '
	echo '██║██╔████╔██║███████║██║  ███╗█████╗      ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     █████╗  ██████╔╝ '
	echo '██║██║╚██╔╝██║██╔══██║██║   ██║██╔══╝      ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ██╔══╝  ██╔══██╗ '
	echo '██║██║ ╚═╝ ██║██║  ██║╚██████╔╝███████╗    ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗███████╗██║  ██║ '
	echo '╚═╝╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝ '
	echo '                                                                                                                  '
	echo '                                                                                                                  '
	echo '                                                                                                                  '
	echo '█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗'
	echo '╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝'
}


print_usage() 
{
	echo "usage: $0 image_file num_nodes" 
}

parse_arguments() 
{
	num_re='^[0-9]+$'

	if [ -z "${image_file}" ]
	then
		print_usage
		exit 1
	fi

	if [ -z "${num_nodes}" ] || ! [[ ${num_nodes} =~ ${num_re}  ]]
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
	# copy first run configuration script to
	# the root folder, it will be picked up from
	# there on the first boot by the cron job.
	# first-boot.sh script will then remove itself
	# from crontab and disk after running
	echo "installing first run script"

	cp -r ${script_dir}/first-boot/ ${image_mountpoint}/root/first-boot/

	# define first boot cron job
	echo "@reboot root /bin/bash /root/first-boot/setup.sh" >> ${image_mountpoint}/etc/crontab
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

	echo "node's ${node} os image installed successfully"
}

insert_card_prompt()
{
	read -p "Insert card $1 of $2 and press [RETURN] to continue..."
}

parse_arguments

banner

for (( node=1; node<=${num_nodes}; node++ ))
do
	insert_card_prompt ${node} ${num_nodes}
	install_image
done

