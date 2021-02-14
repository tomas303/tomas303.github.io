---
layout: post
title:  "LeEco le2 upgrade 2"
date:   2021-02-14 12:00:00
categories: mobile
---

Leeco s2 upgrade 17.1 has arrived and I have installed it. Sideload didn't work this time so I installed files directly from twrp as described in [installfromtwrp][lineageos-installfromtwrp].

I flashed last twrp recovery image:

Enter into fastboot mode.
{% highlight cmd %}
adb reboot bootloader
{% endhighlight %}

Verify fastboot recognises my phone
{% highlight cmd %}
fastboot devices
cd6ab2fd	fastboot
{% endhighlight %}

flash the recovery
{% highlight cmd %}
fastboot flash recovery ./twrp-3.5.0_9-0-s2.img
Sending 'recovery' (24618 KB)                      OKAY [  0.776s]
Writing 'recovery'                                 OKAY [  0.372s]
Finished. Total time: 1.159s
{% endhighlight %}

I verified I can boot newly flashed twrp recovery image holding Volume Up + Power.

After that I started sideload from twrp via Advanced / ADB Sideload and tried to sideload image file. This ended with error 7 and it means, that installed system differs from existing. That was true since I tried to upgrade from 16 to 17.1.

I Formatted data and wiped the Cache and System partitions from twrp(Advanced Wipe) mentioned in [lineageos install][lineageos-install]. I am not sure if this is right step, in  [lineageos upgrade][lineageos-upgrade] is only data partition wiping mentioned.

This time sideload ended with error:
{% highlight cmd %}
adb: sideload connection failed: closed
adb: trying pre-KitKat sideload method...
adb: pre-KitKat sideload connection failed: closed
{% endhighlight %}

I searched google for solution but non helped me. I finally discovered usefull solution here [lineageos installfromtwrp][lineageos-installfromtwrp]. It describes how to run installation directly from twrp.

I mounted storage(twrp mount and then mount USB storage), copied necessary files to mobile(lineage-17.1-20210208-recovery-s2.img and open_gapps-arm64-10.0-nano-20210213.zip) and then based on [lineageos installfromtwrp][lineageos-installfromtwrp] chose "Install" in twrp, selected image file first, then clicked "Add more Zips" button and seleted open gapps. And then swiped right to confirm flash. This worked as expected. So next time if I won't change twrp partition I can skip use of android platform tools altogether.


[lineageos-upgrade]: https://wiki.lineageos.org/devices/s2/upgrade
[lineageos-install]: https://wiki.lineageos.org/devices/s2/install
[lineageos-installfromtwrp]: https://www.howtogeek.com/348545/how-to-install-lineageos-on-android
