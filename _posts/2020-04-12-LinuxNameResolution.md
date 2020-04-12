---
layout: post
title:  "linux name resolution and go binaries"
date:   2020-04-12 00:00:00
categories: bash linux nslookup getent
---

I encountered a problem when trying to setup backup with restic. I run restserver on one of my computer and tried to run backup from other computer. I have zeroconf using avahi on each computer in my home network. When I run backup command(tmp directory is just for illustration) I received error message:

```bash
restic backup -r rest:http://plechy.local:8000/tmp /tmp
```

```bash
Fatal: unable to open config file: client.Head: Head http://plechy.local:8000/tmp/config: dial tcp: lookup plechy.local on 127.0.1.1:53: no such host
Is there a repository at the following location?
rest:http://plechy.local:8000/tmp
```
Ping command on the other hand worked as expected:

```bash
ping plechy.local
```
```bash
PING plechy.local (192.168.2.7) 56(84) bytes of data.
```

Finally I found out [here][go net package] and [here][go name resolution] that go can be compiled to call just DNS lookup and bypass [linux resolution][Linux name resolution]. I downloaded binaries from restic web page. Setting GODEBUG variable revealed that binaries are not compiled with cgo and DNS lookup only is proceed. Binaries included in opensuse distribution behaves correctly.

```bash
export GODEBUG=netdns=cgo+1
restic backup -r rest:http://plechy.local:8000/tmp /tmp
```
```bash
go package net: built with netgo build tag; using Go's DNS resolver
Fatal: unable to open config file: client.Head: Head http://plechy.local:8000/tmp/config: dial tcp: lookup plechy.local on 127.0.1.1:53: no such host
Is there a repository at the following location?
rest:http://plechy.local:8000/tmp
```

As a temporal solution I use getent utility in script to find out ip address and then supply it to command. getent resolve name according nsswitch.conf - nice explanation how this all works is [here][Linux name resolution].

```bash
getent hosts plechy.local
```

```bash
192.168.2.7     plechy.local
```

Utility nslookup resolve name via DNS only. And of course I got same result as restic program. So for debugging net problems is good to know both those utilities and how they work.

```bash
 nslookup plechy.local
```
```bash
Server:		127.0.1.1
Address:	127.0.1.1#53

** server can't find plechy.local: NXDOMAIN
```


* [Linux name resolution]
* [go net package]
* [go name resolution]
* [restic]

[Linux name resolution]: https://javarevisited.blogspot.com/2017/04/how-hostname-to-ip-address-conversion-or-name-resolution-works-in-Linux.html
[go net package]: https://golang.org/pkg/net/
[go name resolution]: https://utcc.utoronto.ca/~cks/space/blog/programming/GoNetLookupsCgoAndLinux
[restic]: https://restic.net/