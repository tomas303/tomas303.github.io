---
layout: post
title:  "android compile"
date:   2023-12-25 01:00:00
categories: os android
---

I have inherited a mobile xiaomi toco which isn't directly supported by lineageos
but has support of elixir os. So I forked out toco device tree(see tomas303 paths
inside manifest) and after some tries and mistakes was able to compile the android
system and succesfully flash it.
I have created simple [droid build container] with software neccessary to build android.
It is better to go container way and don't polute main os. I use this image inside
microos like this:

~~~cmd
distrobox create \
  --name droidbuilder \
  --home <some directory, otherwise current home will be used> \
  --image localhost/droid:latest
~~~

Installing repo, platform-tools, creating dirs and set up some git basics are all
parts of the docker script, so here I put only some very basic commands how to
start and run compilation:

~~~cmd
distrobox enter droidbuilder
cd ~/android/lineage
repo init -u https://github.com/LineageOS/android.git -b lineage-20.0 --git-lfs
repo sync
. ./build/envsetup.sh
lunch lineage_toco-userdebug
mka bacon
~~~

One can run lunch without parameters and it will list some of possible combinations.
I learned that usualy it is userdebug build. Contrary to it's name is not too slow
compared to lineage_toco-user and I think I have read somewhere this is build used
by lineageos. lineage_toco-user wasn't compilable anyway. For real debugging is
used lineage_toco-eng build.
Between repo init and repo sync local manifest is needed to be put into
/.repo/local_manifests. It could be put there later and then run repo sync again.
Actual content I use now is:

~~~html
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remote name="gitlab" fetch="https://gitlab.com" />

  <project path="device/xiaomi/toco" remote="github" name="tomas303/device_xiaomi_toco" revision="tiramisu" />
  <project path="device/xiaomi/sm6150-common" remote="github" name="tomas303/device_xiaomi_sm6150-common-toco" revision="tiramisu" />
  <project path="vendor/xiaomi" remote="github" name="AndroidHQ254/vendor_xiaomi" revision="tiramisu" />
  <project path="hardware/xiaomi" remote="github" name="AndroidHQ254/android_hardware_xiaomi" revision="13" />
  <project path="vendor/xiaomi/toco-miuicamera" remote="gitlab" name="AndroidHQ254/vendor-xiaomi-toco-miuicamera" revision="leica" />
  <project path="kernel/xiaomi/sm6150" remote="github" name="vantoman/kernel_xiaomi_sm6150" revision="13" />
  <project path="vendor/gapps" name="MindTheGapps/vendor_gapps" remote="gitlab" revision="tau" />
</manifest>
~~~

Sync of repo sucks and sometimes get stuck in 99% and need to be interrupted and
run again.
Repeat build just starts from repo sync onward. Mka clean is necessary to run
before to clean up all previously builded parts.

This toco-miuicamera actually don't work(no idea, didn't investigate) so I use
simple camera and simple gallery from [fdroid repo] instead. Be aware that
creator sold out the sources (it's been disussed on a simple mobile tools
as an issue). Versions on [fdroid repo] are still original. There is a [FossifyOrg]
fork what will probably take on open source development.

Flash system is easy:

~~~cmd
~/android-sdk/platform-tools/fastboot flash recovery ~/android/lineage/out/target/product/toco/recovery.img
~/android-sdk/platform-tools/fastboot reboot recovery
~/android-sdk/platform-tools/adb -d sideload ~/android/lineage/out/target/product/toco/lineage-20.0-20231214-UNOFFICIAL-toco.zip
~~~

You need to have access for device beeing flash to. I used [udev rule for android]
to create such rule and placed it inside host sytem /etc/udev/rules.d directory
(distrobox use device from host).
Rule(named 51-android.rules) works fine:

~~~cmd
SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="4ee7", MODE="0660",
GROUP="<somegroup>", SYMLINK+="android%n"
~~~

You can use whatever group suits you.

There were instructions about wipe super_empty.img - it's done
as fastboot wipe-super super_empty.img. Not sure if it's
necessary. Img file can be found somewhere inside out directory
structure.

As of now side load other apps like gapps isn't possible because
system and other partitions are type erofs - read only filesystem.
This is a reason why gapps are part of manifest file and are included
in finished zip file.

Links:

* [LineageOS]
* [droid build container]
* [fdroid repo]
* [udev rule for android]

[LineageOS]: https://github.com/LineageOS/android.git
[droid build container]: https://github.com/tomas303/dockerscripts/tree/master/droid
[fdroid repo]: https://f-droid.org/
[FossifyOrg]: https://github.com/FossifyOrg
[udev rule for android]: https://www.janosgyerik.com/adding-udev-rules-for-usb-debugging-android-devices/
