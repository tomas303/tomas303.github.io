---
layout: post
title:  "virtual box vfa resolution"
date:   2019-11-16 20:00:00
categories: virtualbox resolution vga grub
---
I have installed basic debian system in my virtualbox to play with a docker inside it. Debian has no x windows system installed and by default has a resolution 800x600. Id didn't bother me much cause I log there by ssh from my host system. But I started to play with x windows inside some containers recently, so I needed to figure out, how to change console resolution.


First valuable information was about how to find supported possible resolutions. With info taken from [find out resoution from grub console][grub2-resolution] I rebooted debian, pressed c key to enter to grub console and run vbeinfo command. Unfotunately there was no fullhd resolution - native resolution of my host system - listed.

Here helped me this [resolution discussion thread][virtualbox-resolutionwihoutGAs] which redirected me to [virtualbox add custom resolution][virtualbox-advanceddisplayconfiguration]. Here in section "9.7.1. Custom VESA Resolutions" is instruction how to add custom resolution.

I run following command to add fullhd resolution. Docker2 is name of my virtual machine, CustomVideoMode1 is name constructed based on info from [virtualbox-advanceddisplayconfiguration]. You can have from 1 up to 16 custom modes defined.

{% highlight cmd %}
vboxmanage setextradata "docker2" "CustomVideoMode1" "1920x1080x32"
{% endhighlight %}

New mode was now listed with vbeinfo.

Btw other handy command to display all extra data is

{% highlight cmd %}
vboxmanage getextradata "docker2" enumerate
{% endhighlight %}

Next I used file /etc/defult/grub to take new resolution into account. [Based on vga param info] [linux-vgaparam] I added video=1920x1080 to linux default command line parameter and added setting of GRUB_GFXPAYLOAD_LINUX variable so those rows in my /etc/defult/grub file looks like this:

{% highlight cmd %}
...
GRUB_CMDLINE_LINUX_DEFAULT="quiet video=1920x1080"
...
GRUB_GFXPAYLOAD_LINUX=1920x1080
...
{% endhighlight %}

Based on instructions I used update-grub command to actualize grub.cfg. But unfortunatelly this command didn't work as expected and din't change anything in grug.cfg. I used grub-mkconfig instead and my new resolution has finally started to work.

{% highlight cmd %}
grub-mkconfig -o /boot/grub/grub.cfg
{% endhighlight %}

Btw whe I run update-grub first time it gave me message "command not found". I [found a solution here] [grub2-updategrub] and use su - root indeed helped me.






# Links:
* [find out resoution from grub console][grub2-resolution]
* [grub gfxmode info][grub2-gfxmode]
* [grub gfxpayload info][grub2-gfxpayload]
* [update-grub not found][grub2-updategrub]
* [resolution discussion thread][virtualbox-resolutionwihoutGAs]
* [virtualbox add custom resolution][virtualbox-advanceddisplayconfiguration]


[grub2-resolution]: https://wiki.sabayon.org/index.php?title=HOWTO:_Using_Custom_Framebuffer_Resolution_with_GRUB2
[grub2-gfxmode]: https://www.gnu.org/software/grub/manual/grub/html_node/gfxmode.html#gfxmode
[grub2-gfxpayload]: https://www.gnu.org/software/grub/manual/grub/html_node/gfxpayload.html
[virtualbox-resolutionwihoutGAs]: https://forums.virtualbox.org/viewtopic.php?f=1&t=84679
[virtualbox-advanceddisplayconfiguration]: https://www.virtualbox.org/manual/ch09.html#adv-display-config
[grub2-updategrub]: https://unix.stackexchange.com/questions/482569/debian-10-buster-update-grub-command-not-found

[linux-vgaparam]: https://unix.stackexchange.com/questions/314402/grub2-resolution-setting-not-respected-by-debian-garbage-on-screen