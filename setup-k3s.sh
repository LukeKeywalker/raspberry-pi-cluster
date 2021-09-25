#! /bin/bash

num_master_nodes=$1
num_worker_nodes=$2
rsa_pub_key=$3

print_usage()
{
	echo "usage: $0 num_master_nodes num_worker_nodes" 
}

parse_arguments() 
{
	num_re='^[0-9]+$'

	if [ -z "${num_master_nodes}" ] || [[ ! ${num_master_nodes} =~ ${num_re}  ]] || [[ ${num_master_nodes} -le 0 ]]
	then
		print_usage
		exit 1
	fi

	if [ -z "${num_worker_nodes}" ] || [[ ! ${num_worker_nodes} =~ ${num_re}  ]]
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

parse_arguments

# install cluster with first master node at 192.168.1.11
k3sup install --cluster \
	--k3s-extra-args "--no-deploy traefik" \
       	--ip 192.168.1.11 \
	--user root \
	--ssh-key ${rsa_pub_key}

# join rest of master nodes
for ((node=2; node<=${num_master_nodes}; node++))
do
	node_ip="192.168.1.$((10+${node}))"
	k3sup join --ip ${node_ip} \
		--server \
	        --k3s-extra-args "--no-deploy traefik" \
		--user root \
		--ssh-key ${rsa_pub_key} \
		--server-user root \
		--server-ip 192.168.1.11
done

# join worker nodes
for ((node=1; node<=${num_worker_nodes}; node++))
do
	node_ip="192.168.1.$((10+${num_master_nodes}+${node}))"
	k3sup join --ip ${node_ip} \ 
	        --k3s-extra-args "--no-deploy traefik" \
		--user root \
		--ssh-key ${rsa_pub_key} \
		--server-user root \
		--server-ip 192.168.1.11
done

# install kubeconfig
mv kubeconfig ~/.kube/

# label worker nodes
for i in {1..${num_worker_nodes}}; do kubectl label node worker-${i} node-role.kubernetes.io/worker=worker; done
