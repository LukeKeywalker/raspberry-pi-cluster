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
