# raspberry-pi-cluster

Raspberry Pi mac addresses start with [`dc:a6:32`](https://maclookup.app/macaddress/DCA632)

command for getting ip addresses for all rpis on the network:
```
arp -e | grep "dc:a6:32" | awk '{ print $3 }'
```


## cgroup memory settings
add this at the end of `/boot/cmdline.txt`

```
sed '$s/$/ cgroup_memory=1 cgroup_enable=memory/' /boot/cmdline.txt > cmdline.tmp
mv cmdline.tmp /boot/cmdline.txt
```

## set hostnames

### master nodes
```
hostnamectl set-hostname master-node-n
```

### worker nodes
```
hostnamectl set-hostname worker-node-n
```

### all the nodes
```
echo '192.168.1.11   		master-{i}.k3s.local		master-node-1'	 >> /etc/hosts
...
echo '192.168.1.{n} 		master-{i}.k3s.local 		master-node-{n}' >> /etc/hosts
echo '192.168.1.{n + 1} 	worker-{n + 1}.k3s.local 	worker-node-1' 	 >> /etc/hosts
...
echo '192.168.1.{n + k}		worker-{n + k}.k3s.local	worker-node-{k}' >> /etc/hosts
```

## firewall setup

### master nodes
```
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10251/tcp
firewall-cmd --permanent --add-port=10252/tcp
firewall-cmd --permanent --add-port=10255/tcp
firewall-cmd --reload
```

### worker nodes
```
firewall-cmd --permanent --add-port=10251/tcp
firewall-cmd --permanent --add-port=10255/tcp
firewall-cmd --reload
```

## update iptables settings (all nodes)
```
echo 'net.bridge.bridge-nf-call-ip6tables = 1' > /etc/sysctl.d/k8s.conf
echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.d/k8s.conf
sysctl --system
```

## disable swap memory (all nodes)
```
sed -i '/swap/d' /etc/fstab
swapoff -a
```

## disable SELinux (all nodes)
```
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
```

# Creating K3S cluster with K3Sup

master node assumed to have ip `192.168.1.16`

## create master node
```
k3sup install --cluster --ip 192.168.1.16 --user root --ssh-key ~/.ssh/rpi-cluster 
```

## join worker nodes to the cluster
```
for i in {1..5}; do k3sup join --ip 192.168.1.1${i} --user root --ssh-key ~/.ssh/rpi-cluster --server-user root --server-ip 192.168.1.16; done
```

