---
layout: post
title:  "Ethernet half speed"
date:   2022-04-10 01:00:00
categories: system net
---
I had wondered why the speed of my 1GB network was only half when compared with other comps in my network. I have measured it with iperf3 tool. Finally I found out that there is a bug in kernel for e1000e driver - [kernel-problem][kernel-problem].

I have followed instructions there and created systemd service _/etc/systemd/system/nic-config.service with this content_:

{% highlight cmd %}
# solve problem when i219-lm ethernet device runs half gigabit of speed
[Unit]
Description=NIC configuration service
After=network.target

[Service]
Type=simple
ExecStart=ethtool -K enp0s31f6 tso off gso off
Restart=on-failure

[Install]
WantedBy=multi-user.target
{% endhighlight %}

You can get service running with the help of this commands:
{% highlight cmd %}
systemctl enable nic-config.service
systemctl start nic-config.service
systemctl status nic-config.service
systemctl daemon-reload
{% endhighlight %}



[kernel-problem]: https://archived.forum.manjaro.org/t/solved-only-half-gigabit-eth-with-intel-i219-lm-v-under-kernel-4-14-to-4-19/58886/36
