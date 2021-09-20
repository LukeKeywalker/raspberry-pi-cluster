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
for some reason first firewall-cmd is not applied and has to be re-applied manually after the k3sup had beed installed
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

see `setup-k3s.sh`

# WireGuard

`yum update -y` is needed before WireGuard can be compiled from sources (there will be compilation errors otherwise)

wireguard needs to be installed from source on raspberry pi CentOS 7 (arm build not available in ElRepo)

installing proper kernel development package:

```
yum install "kernel-devel-uname-r == $(uname -r)" -y
```
rest of dependencies:
```
yum install elfutils-libelf-devel kernel-devel pkgconfig "@Development Tools" -y
```

install git
```
yum install git -y
```
grab the code
```
git clone https://git.zx2c4.com/wireguard-linux-compat
git clone https://git.zx2c4.com/wireguard-tools
```
compile and install kernel module:
```
make -C wireguard-linux-compat/src -j$(nproc)
sudo make -C wireguard-linux-compat/src install
```
compile and install wg tool:
```
make -C wireguard-tools/src -j$(nproc)
sudo make -C wireguard-tools/src install
```


Create client configuration file:
```
sudo mkdir -p /etc/wireguard/
cd /etc/wireguard
wg genkey | sudo tee /etc/wireguard/client_private.key | wg pubkey | sudo tee /etc/wireguard/client_public.key
```

Client config file content:
```
vim /etc/wireguard/wg-client0.conf
```

```
[Interface]
Address = 10.10.10.2/24
DNS = 10.10.10.1
PrivateKey = private-key-of-your-client

[Peer]
PublicKey = public-key-of-your-server
AllowedIPs = 0.0.0.0/0 # to allow untunneled traffic, use `0.0.0.0/1, 128.0.0.0/1` instead
Endpoint = public-ip-of-your-server:51820
PersistentKeepalive = 25
```
Starting wg interface on the client:
```
systemctl start wg-quick@wg-client0.service
```

# Disabling Traefik ingress

To do on the master nodes:

Remove traefik helm chart resource
```
kubectl -n kube-system delete helmcharts.helm.cattle.io traefik
```

Stop the k3s service
```
service k3s stop
```
    
Edit service file `/etc/systemd/system/k3s.service` and add this line to ExecStart:
```
    --no-deploy traefik \
```
* Reload the service file
```
systemctl daemon-reload
```
* Remove the manifest file from auto-deploy folder
```
rm /var/lib/rancher/k3s/server/manifests/traefik.yaml
```
* Start the k3s service:
```
service k3s start
```

