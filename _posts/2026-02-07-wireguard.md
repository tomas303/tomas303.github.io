---
layout: post
title:  "wireguard remarks"
date:   2026-02-07 01:00:00
categories: wg wireguard linux tool
---

Bring down wg interface first before doing changes to configuration files.
Some changes can be made on running instance but when bring service down,
configuration file can be overriden by actual runtime setup.

~~~cmd
wg-quick down wg0
~~~

And then bring it up again:
~~~cmd
wg-quick up wg0
~~~

Generate new key pair:
~~~cmd
wg genkey | tee keyx_priv | wg pubkey > keyx_pub
~~~

And then create config file to be imported by network managar f.e.
~~~cmd
[Interface]
PrivateKey = <content of keyx_priv>
Address = 10.1.1.5/32

[Peer]
PublicKey = <content of public key of peer to connect to>
Endpoint = <some ip>:<port>
AllowedIPs = 10.1.1.0/24
PersistentKeepalive = 21
~~~

So this is typical client configuration to connect to some wireguard VPN. Usually server is configured
as a hub. Server's public key goes to Peer section public key and our public key will participate
in servers configuration - f.e. in /etc/wireguard/wg0.conf:

~~~cmd
[Interface]
Address = 10.1.1.1/24
SaveConfig = true
ListenPort = 51820
PrivateKey = <server's private key>

[Peer]
PublicKey = <public key of first peer>
AllowedIPs = 10.1.1.5/32

[Peer]
PublicKey = <public key of second peer> 
AllowedIPs = 10.1.1.6/32
~~~

So server has address 10.1.1.1, first client 10.1.1.5, second 10.1.1.6 and so on. This is so called split tunnel
so only allowed ips traffic is routed via vpn.


AllowedIPs:
 - client: 
   - act as routing table, so whatever in it's range goes via vpn.
 - server:
   - when source ip doesnt match, rejects it
   - as which packet to route via this pear(so it must be unique ip)

Address section add IP for this interface and in case of subnet aswell routing rule.
But which packet goes through is ultimatelly based on AllowedIPs in case of overlaping. 
Don't know more details how those 2 interacts.


Linux server need to be configured to pass traffic between peers: 
~~~cmd
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
sysctl -p
~~~




## Some info for cidr notation of Address and AllowedIPs as I got them via chatgpt:

Cidr in address is to inform OS that link is part of segment and other
addresses are directly reachable - most commonly on ethernet via L2 ARP
protocol. So OS usually create LINK entry in route table to direct
such packets here.

Now wireguard is only point to point device on L3 level - so working
via ip addresses. While it can and is used to simulate virtual LAN,
it is not really LAN - no broadcast, no ARP, no L2 discovery.
Each peer is a single logical endpoint.

When packet ends in wg interface stack the device will do
what is programmed to do - compare it with allowedips and if is in range
then sent it forward via tunnel. So even if client misconfigured
cidr in address it will work. But it is still misconfitured and fragile.
Ultimate rules what goes to wg VPN endpoint here are AllowedIPs.

# CLIENT

32 CIDR in Address field is most commonly right value.
24 or less in AllowedIPs routes those addresses via VPN. But here can
be whateever traffic client wants to go via VPN. This field can
be multiple times in configuration.

# SERVER

in hub and spoke scenario server maintain set of peers which usually wants to communicate each other.
So 24 CIDR in Address field here is ok and expected - this device is really next hop for such packets.
AllowedIPs of each peer is expected to have 32 CIDR on other hand as this
device routes individual traffic between peers.

This is common scenario of simulating vlan with wg(but as is written above wg will never
behave like real lan). There are of course many other scenarios but I wanted to have just
one segment for small amount of peers to communicate each other. I added last paragraph to
understand what purpose cidr in address and allowedips serves.

Cidr in address has nothing to do with wireguard internals - it is common thing to setup network
interfaces and behavior depends on target interface. Real ethernet device will sent packet via ARP,
wg will just process it as is programmed(decide based on allowedips if route it via vpn) 
and other net devices will follow their own rules.

Cidr in allowedips is purelly to route traffic via VPN (and on incomming side verify agains source IP).
So routes based on allowedips are added to routing table too. Both places
participates in routing table but each one from different reasons. And this is why is difficult
to find a problem, because misconfigured devices still can sometimes work as expected
and sometimes not.







