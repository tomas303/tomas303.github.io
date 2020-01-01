---
layout: post
title:  "LeEco le2 upgrade"
date:   2019-12-31 12:00:00
categories: mobile
---

Leeco s2 upgrade 16.0 has finally arrived but upgrade installation isn't automatic. First I decided to install latest twrp custom recovery so I followed [lineageos install custom recovery][lineageos-installcustomrecovery] instructions.

Allow android debuging - see [lineageos setup adb][lineageos-setupadb]. It is Android debugging switch under Developer options.
{% highlight cmd %}
adb devices
List of devices attached
cd6ab2fd	device
{% endhighlight %}

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
fastboot flash recovery ./leecos2upgrade/twrp-3.3.1-0-s2.img
Sending 'recovery' (24618 KB)                      OKAY [  0.776s]
Writing 'recovery'                                 OKAY [  0.372s]
Finished. Total time: 1.159s
{% endhighlight %}

I verified I can boot newly flashed twrp recovery image holding Volume Up + Power.



After that I followed [upgrade instructions][lineageos-upgrade].

Running sideload command raised an root privileges error:
{% highlight cmd %}
adb reboot sideload
'adb root' is required for 'adb reboot sideload'.
{% endhighlight %}

I booted into recovery mode and started sideload from there.
{% highlight cmd %}
adb reboot recovery
{% endhighlight %}

Now go into Advanced / ADB Sideload, start sideload and then send needed files via adb. I chose to install MindTheGapps and addonsu too. Start sideload is needed for each file to sent.
{% highlight cmd %}
adb sideload ./leecos2upgrade/lineage-16.0-20191230-nightly-s2-signed.zip
Total xfer: 1.00x
adb sideload ./leecos2upgrade/MindTheGapps-9.0.0-arm64-20190615_031441.zip
Total xfer: 1.01x
adb sideload ./leecos2upgrade/addonsu-16.0-arm64-signed.zip
Total xfer: 1.37x
{% endhighlight %}

One need to pay attention to messages on mobile after each sideload. I really don't know what happened, but first time I rebooted mobile got stuck in lineage os logo for about 30 minutes. After that I aborted whatever was going on there, rebooted and tried to repeat sideload. Sideloading of lineageos image now ended with error 7 each time. I fiddled with couple of things in twrp. Final steps what helped me was probably Wipe / Format data followed by Advanced wipe with Dalvik / ART Cache, Cache, System, Data checked on. After that sideloading of files ended up with succes and next reboot took just couple of minutes.

I checked install twrp app before reboot on the first try and skipped it on the second try. This could make a difference too but don't know for sure.

[lineageos-upgrade]: https://wiki.lineageos.org/devices/s2/upgrade
[lineageos-install]: https://wiki.lineageos.org/devices/s2/install
[lineageos-setupadb]: https://wiki.lineageos.org/adb_fastboot_guide.html#setting-up-adb
[lineageos-installcustomrecovery]: https://wiki.lineageos.org/devices/s2/install#installing-a-custom-recovery-using-fastboot
