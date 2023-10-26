---
layout: post
title:  "slow disk with restic backup"
date:   2023-10-26 01:00:00
categories: hardware speed 
---
I run restic to backup may work computer mainly including couple of virtual disk
images with total size around 150 GB. Restic server runs on freebsd server and
backup is located on zfs pool made of two 2TB mirrored disks. It took literally
hours and situation was more and more worse. I googled net for some advice to
find the culprit and it paid off.

First I used gstat utility with 3 seconds interval:

{% highlight cmd %}
gstat -I 3s

L(q)  ops/s    r/s   kBps   ms/r    w/s   kBps   ms/w   %busy Name
    0      0      0      0    0.0      0      0    0.0    0.0| ada0
    0      0      0      0    0.0      0      0    0.0    0.0| ada1
{% endhighlight cmd %}

Output is just for illustration, but in my case one disk was way too slow
during backup. Both were part of one mirror so one could expect similar values
for both.

Running
{% highlight cmd %}
smartctl -a /dev/ada1
{% endhighlight cmd %}

revealed, that disk is actually based on SMR technology. You can find plenty
of problems about SMR disks used in mirrod systems. When I exchanged disk,
backup(runned together with sweep) took couple of minutes instead couple of hours.
Just to mention last utility - geom disk list - it gaves some insight about
disks too.
