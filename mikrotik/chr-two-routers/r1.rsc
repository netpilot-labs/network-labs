/interface bridge add name=loopback0
/ip address add address=10.0.12.1/30 interface=ether2
/ip address add address=10.255.0.1/32 interface=loopback0
/routing ospf instance add name=default router-id=10.255.0.1 version=2
/routing ospf area add name=backbone area-id=0.0.0.0 instance=default
/routing ospf interface-template add area=backbone interfaces=ether2 type=ptp
/routing ospf interface-template add area=backbone interfaces=loopback0 passive
