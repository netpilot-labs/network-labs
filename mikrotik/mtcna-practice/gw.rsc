/ip dhcp-client add interface=ether2 add-default-route=yes use-peer-dns=no
/interface bridge add name=lan
/interface bridge port add bridge=lan interface=ether3
/interface bridge port add bridge=lan interface=ether4
/ip address add address=192.168.88.1/24 interface=lan
/ip pool add name=lan-pool ranges=192.168.88.100-192.168.88.150
/ip dhcp-server add name=lan-dhcp interface=lan address-pool=lan-pool lease-time=1h
/ip dhcp-server network add address=192.168.88.0/24 gateway=192.168.88.1 dns-server=192.168.88.1
/ip firewall nat add chain=srcnat out-interface=ether2 action=masquerade comment="LAN to WAN"
/ip firewall filter add chain=input connection-state=established,related action=accept comment="input: return traffic"
/ip firewall filter add chain=input connection-state=invalid action=drop comment="input: drop invalid"
/ip firewall filter add chain=input protocol=icmp action=accept comment="input: ping"
/ip firewall filter add chain=input in-interface=lan action=accept comment="input: from LAN"
/ip firewall filter add chain=input in-interface=ether2 action=drop comment="input: drop from WAN"
/ip firewall filter add chain=forward connection-state=established,related action=accept comment="forward: return traffic"
/ip firewall filter add chain=forward connection-state=invalid action=drop comment="forward: drop invalid"
/ip firewall filter add chain=forward in-interface=lan out-interface=ether2 action=accept comment="forward: LAN to WAN"
/ip firewall filter add chain=forward connection-nat-state=dstnat action=accept comment="forward: port forwards"
/ip firewall filter add chain=forward action=drop comment="forward: drop everything else"
