---
layout: post
title:  "Kvm windows guest clipboar"
date:   2024-10-27 01:00:00
categories: kvm windows clipboard
---

I use a windows 11 guest running inside kvm virtualization. Some time ago
shared clipoboard stopped working and I didn't know why.

I tried to install spice tools only to find out, that I have 2 services
vdagent.

Problem was finally this:

There is a driver on windows what takes care for clipboard and it wasnot
working. It signalized something like this:

Windows cannot verify the digital signature ....

So I uninstall all spicetools and reinstal tools from iso mounted from fedora
(my linux system). But it is not enough - driver is still not loaded. So you need
to click on it, select update and then navigate it to the root of mounted
image to find apropriate driver - and voila, clipoboard has started work
again.

