# The exposed starting state: NAT for the LAN and no firewall rules, so management answers from the WAN.
# Never use this on a real router.
/system identity set name=edge
/interface list add name=WAN
/interface list add name=LAN
/interface list member add list=WAN interface=ether2
/interface list member add list=LAN interface=ether3
/ip address add address=203.0.113.2/24 interface=ether2 comment=WAN
/ip address add address=192.168.88.1/24 interface=ether3 comment=LAN
/ip firewall nat add chain=srcnat out-interface=ether2 action=masquerade comment=LAN-NAT
/ip service set ssh disabled=no
/ip service set www disabled=no
/ip service set winbox disabled=no
/tool bandwidth-server set enabled=yes
