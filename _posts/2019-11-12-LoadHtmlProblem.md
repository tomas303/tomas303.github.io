---
layout: post
title:  "Load html problems"
date:   2019-11-12 12:00:00
categories: html dns
---

# Short version:
Handfull html pages didn't display correctly on newly installed computer. Aliexpress was one of them f.e. It gave me a while to realize problem is somewhere around my provider's DNS server. It just didn't resolve some link names leading to incomplete load of some resources causing html page looking messy. I has used well known google's DNS servers 8.8.8.8 and 8.8.4.4 and voila - problem solved.

# Long version:
I decided to reinstall my home pc with open suse tumbleweed. There was linux mint with kde installed. Because Linux mint no longer support kde directly I decided to give open suse a try. That said I quite like linux mint distro and have got linux mint cinnamon installed on my laptop at the moment. But folks at home are used to kde.
So after reinstall I have to deal with the fact, that on this system aliexpess page looked messy why on my laptop it was displayed correctly.
There are develepoment tools in most nowadays browsers and in one tab were various links and their status. Red ones was the ones with unsuccesfull load. Finally I found out that I set up google's DNS's servers on my laptop quite time ago. And in my previous linux mint distro probably aswell. So this time I just set up DNS's servers directly in my router and made a notice here. Setting them up directly in network manager doesn't seem to work out of the box.

