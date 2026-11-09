/ip address add address=198.51.100.1/24 interface=ether2
/ip address add address=203.0.113.1/24 interface=ether3
/ip pool add name=wan-pool ranges=198.51.100.10-198.51.100.20
/ip dhcp-server add name=wan-dhcp interface=ether2 address-pool=wan-pool lease-time=1h
/ip dhcp-server network add address=198.51.100.0/24 gateway=198.51.100.1 dns-server=198.51.100.1
