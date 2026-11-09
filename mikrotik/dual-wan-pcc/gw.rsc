/ip address add address=10.1.0.2/30 interface=ether2 comment=WAN1
/ip address add address=10.2.0.2/30 interface=ether3 comment=WAN2
/ip address add address=192.168.88.1/24 interface=ether4 comment=LAN
/routing table add name=to_wan1 fib
/routing table add name=to_wan2 fib
/ip firewall mangle add chain=prerouting in-interface=ether2 connection-mark=no-mark action=mark-connection new-connection-mark=wan1_conn passthrough=yes
/ip firewall mangle add chain=prerouting in-interface=ether3 connection-mark=no-mark action=mark-connection new-connection-mark=wan2_conn passthrough=yes
/ip firewall mangle add chain=prerouting in-interface=ether4 dst-address-type=!local connection-mark=no-mark per-connection-classifier=both-addresses-and-ports:2/0 action=mark-connection new-connection-mark=wan1_conn passthrough=yes
/ip firewall mangle add chain=prerouting in-interface=ether4 dst-address-type=!local connection-mark=no-mark per-connection-classifier=both-addresses-and-ports:2/1 action=mark-connection new-connection-mark=wan2_conn passthrough=yes
/ip firewall mangle add chain=prerouting in-interface=ether4 connection-mark=wan1_conn action=mark-routing new-routing-mark=to_wan1 passthrough=no
/ip firewall mangle add chain=prerouting in-interface=ether4 connection-mark=wan2_conn action=mark-routing new-routing-mark=to_wan2 passthrough=no
/ip firewall mangle add chain=output connection-mark=wan1_conn action=mark-routing new-routing-mark=to_wan1 passthrough=no
/ip firewall mangle add chain=output connection-mark=wan2_conn action=mark-routing new-routing-mark=to_wan2 passthrough=no
/ip firewall nat add chain=srcnat out-interface=ether2 action=masquerade
/ip firewall nat add chain=srcnat out-interface=ether3 action=masquerade
/ip route add dst-address=0.0.0.0/0 gateway=10.1.0.1 routing-table=to_wan1 check-gateway=ping
/ip route add dst-address=0.0.0.0/0 gateway=10.2.0.1 routing-table=to_wan1 distance=2
/ip route add dst-address=0.0.0.0/0 gateway=10.2.0.1 routing-table=to_wan2 check-gateway=ping
/ip route add dst-address=0.0.0.0/0 gateway=10.1.0.1 routing-table=to_wan2 distance=2
/ip route add dst-address=0.0.0.0/0 gateway=10.1.0.1 check-gateway=ping
/ip route add dst-address=0.0.0.0/0 gateway=10.2.0.1 distance=2
