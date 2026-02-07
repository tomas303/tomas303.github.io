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
Address = 10.1.1.5/24

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
