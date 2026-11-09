# Hardening for the edge router. Management stays reachable from the LAN only.
# ether1 and 172.20.20.0/24 are containerlab's management port and network: on a real router, drop that rule and that range.
/ip firewall address-list add list=MGMT-ALLOWED address=192.168.88.0/24 comment="LAN admins"
/ip firewall filter add chain=input action=accept connection-state=established,related,untracked comment="accept established, related, untracked"
/ip firewall filter add chain=input action=drop connection-state=invalid comment="drop invalid"
/ip firewall filter add chain=input action=accept protocol=icmp comment="accept ICMP"
/ip firewall filter add chain=input action=accept dst-address=127.0.0.1 comment="accept to local loopback"
/ip firewall filter add chain=input action=accept in-interface=ether1 comment="containerlab management port"
/ip firewall filter add chain=input action=accept in-interface-list=LAN src-address-list=MGMT-ALLOWED comment="management from the LAN only"
/ip firewall filter add chain=input action=drop comment="drop all other input"
/ip firewall filter add chain=forward action=accept connection-state=established,related,untracked comment="forward established, related, untracked"
/ip firewall filter add chain=forward action=drop connection-state=invalid comment="forward drop invalid"
/ip firewall filter add chain=forward action=drop connection-state=new connection-nat-state=!dstnat in-interface-list=WAN comment="drop WAN-initiated connections that are not port forwards"
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes
/ip service set api disabled=yes
/ip service set api-ssl disabled=yes
/ip service set ssh available-from=192.168.88.0/24,172.20.20.0/24
/ip service set winbox available-from=192.168.88.0/24,172.20.20.0/24
/ip service set www available-from=192.168.88.0/24,172.20.20.0/24
/tool bandwidth-server set enabled=no
/ip neighbor discovery-settings set discover-interface-list=LAN
/tool mac-server set allowed-interface-list=LAN
/tool mac-server mac-winbox set allowed-interface-list=LAN
/tool mac-server ping set enabled=no
/ip ssh set strong-crypto=yes
