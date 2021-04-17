# raspberry-pi-cluster

Raspberry Pi mac addresses start with [`dc:a6:32`](https://maclookup.app/macaddress/DCA632)

command for getting ip addresses for all rpis on the network:
```
arp -e | grep "dc:a6:32" | awk '{ print $3 }'
```
