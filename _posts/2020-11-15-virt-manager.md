---
layout: post
title:  "virt-manager"
date:   2020-11-15 12:00:00
categories: virt virtual vbox virtualbox kvm
---

## kvm supports vdi disks

I run virtualbox including window's guest and wanted to give kvm a try. I thought that kvm didn't supported vdi format used by virtualbox or at least didn't find any info about it. I just tried it and it has worked suprisingly well - with little tweaks in configuration. I use virt-manager for configuration.

# CPU
Not all cpu resources are allocated when guest configuration is created. If you want to use all cpu power by one guest, you need to change Topology in CPUs section. I changed it to **1 socket 4 cores 2 threads** accordingly with my i7 processor - one processor, four cores and two threads per core. See [cpu topology] for complete description.

# USB
You can add whatever usb hardware is connected. But by default it's added so that guest system won't start when usb device is currently unconnected. You need to change xml and add startupPolicy set it to optional:

``` xml
  <hostdev mode="subsystem" type="usb" managed="yes">
    <source startupPolicy="optional">
      <vendor id="0x1395"/>
      <product id="0x0025"/>
    </source>
    <address type="usb" bus="0" port="5"/>
  </hostdev>
  ```
See [usb] for complete description.

# Attaching device
You can attach device to running guest system - see [attach device]. Here on [Roland's Blog][autoplug] is described how to use it in conjuction with udev rules, so it basically attach/detach device from guest system when it is plugged/unplugged from host system.
  I created following rules based on advice from  [Roland's Blog][autoplug] and xml above:

``` bash
ACTION=="add", \
    SUBSYSTEM=="usb", \
    ENV{ID_VENDOR_ID}=="1395", \
    ENV{ID_MODEL_ID}=="0025", \
    RUN+="/usr/bin/virsh attach-device GUESTNAME /opt/libvirt/senheiserheadphones.xml"
ACTION=="remove", \
    SUBSYSTEM=="usb", \
    ENV{ID_VENDOR_ID}=="1395", \
    ENV{ID_MODEL_ID}=="0025", \
    RUN+="/usr/bin/virsh detach-device GUESTNAME /opt/libvirt/senheiserheadphones.xml"
```

and placed it into /etc/udev/rules.d/90-libvirt-usb.rules file.



# Links:

* [cpu topology]
* [usb]
* [autoplug]
* [attach device]


[cpu topology]:https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/virtualization_administration_guide/sect-libvirt-dom-xml-cpu-model-top
[usb]:https://libvirt.org/formatdomain.html#host-device-assignment
[autoplug]:https://rolandtapken.de/blog/2011-04/how-auto-hotplug-usb-devices-libvirt-vms-update-1
[attach device]:https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/virtualization_administration_guide/sect-managing_guest_virtual_machines_with_virsh-attaching_and_updating_a_device_with_virsh
