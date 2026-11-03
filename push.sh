cat > edge.rsc <<'EOF_X'
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
EOF_X
cat > harden.rsc <<'EOF_X'
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
EOF_X
cat > mikrotrick-hardening.clab.yml <<'EOF_X'
name: mikrotrick-hardening

topology:
  kinds:
    mikrotik_chr:
      image: mikrotik/chr:7.24.5
    linux:
      image: ghcr.io/srl-labs/network-multitool:latest

  nodes:
    edge:
      kind: mikrotik_chr
      startup-config: edge.rsc
    pc1:
      kind: linux
      exec:
        - ip addr add 192.168.88.10/24 dev eth1
        - ip route add 203.0.113.0/24 via 192.168.88.1
    out:
      kind: linux
      exec:
        - ip addr add 203.0.113.1/24 dev eth1

  links:
    - endpoints: ["edge:ether2", "out:eth1"]
    - endpoints: ["edge:ether3", "pc1:eth1"]
EOF_X
