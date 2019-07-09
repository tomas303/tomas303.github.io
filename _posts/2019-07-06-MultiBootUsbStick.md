---
layout: post
title:  "Multiboot USB stick"
date:   2019-07-06 12:00:00
categories: usb boot iso
---
I use iso images of linuxs' distributions time to time. I moved them to usb based on instructions I found elsewhere. It usually involved using of some kind of tool like unetbootin or USB image writer. When deal with tools capable of erasing your usb stick it is better to use a free usb stick each time. This and desire to understand what's going on under the hood ignited my interest and I decided to explore possibilities and eventually created something more reusable. I ended up with multiboot usb stick based on GRUB bootloader. This is simple solution and works suprisingly well.


# Finding out device name of usb stick
Be carefull because you don't want to write to other disk. You can use whatsever utility like fdisk f.e.
```
# fdisk -l
Disk /dev/sdb: 1,9 GiB, 2021654528 bytes, 3948544 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xde4e8050

Device     Boot Start     End Sectors  Size Id Type
/dev/sdb1  *     2048 3948543 3946496  1,9G  c W95 FAT32 (LBA)
```

# Prepare usb stick
First I removed all partitions from disk. I used gdisk and commands x(switch to expert mode) and z(wipes out GPT partition table). Use whatever suits you. Then I created three new partitions(bios, efi and data) and Hybrid GPT. I closely followed steps described in [arch linux wiki multiboot usb article][archlinux-multibootusb].
```
# gdisk /dev/sdb
GPT fdisk (gdisk) version 1.0.1

Partition table scan:
  MBR: not present
  BSD: not present
  APM: not present
  GPT: not present

Creating new GPT entries.

Command (? for help): n
Partition number (1-128, default 1):
First sector (34-3948510, default = 2048) or {+-}size{KMGTP}:
Last sector (2048-3948510, default = 3948510) or {+-}size{KMGTP}: 2m
Current type is 'Linux filesystem'
Hex code or GUID (L to show codes, Enter = 8300): EF02
Changed type of partition to 'BIOS boot partition'

Command (? for help): n
Partition number (2-128, default 2):
First sector (34-3948510, default = 6144) or {+-}size{KMGTP}:
Last sector (6144-3948510, default = 3948510) or {+-}size{KMGTP}: 50m
Current type is 'Linux filesystem'
Hex code or GUID (L to show codes, Enter = 8300): EF00
Changed type of partition to 'EFI System'

Command (? for help): n
Partition number (3-128, default 3):
First sector (34-3948510, default = 104448) or {+-}size{KMGTP}:
Last sector (104448-3948510, default = 3948510) or {+-}size{KMGTP}:
Current type is 'Linux filesystem'
Hex code or GUID (L to show codes, Enter = 8300):
Changed type of partition to 'Linux filesystem'

Command (? for help): x

Expert command (? for help): h

Expert command (? for help): w

Final checks complete. About to write GPT data. THIS WILL OVERWRITE EXISTING
PARTITIONS!!

Do you want to proceed? (Y/N): y
OK; writing new GUID partition table (GPT) to /dev/sdb.
The operation has completed successfully.
```

# Format new partitions
```
# mkfs.fat -F32 /dev/sdb2
mkfs.fat 3.0.28 (2015-05-16)
# mkfs.ext4 /dev/sdb3
mke2fs 1.42.13 (17-May-2015)
/dev/sdb3 contains a ext4 file system
	created on Mon Jul  8 16:55:24 2019
Proceed anyway? (y,n) y
Creating filesystem with 480507 4k blocks and 120240 inodes
Filesystem UUID: d1186f26-f265-4f90-b345-cdd7fd6342c5
Superblock backups stored on blocks:
	32768, 98304, 163840, 229376, 294912

Allocating group tables: done
Writing inode tables: done
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done
```

# Mount new partitions
```
mkdir -p /mnt/usb
mkdir -p /mnt/usbefi
mount /dev/sdb2 /mnt/usbefi/
mount /dev/sdb3 /mnt/usb/
```


# Install grub for efi
Once again [arch linux wiki multiboot usb article][archlinux-multibootusb].
```
# grub-install --target=x86_64-efi --recheck --removable  --boot-directory=/mnt/usb/boot  --efi-directory=/mnt/usbefi/
Installing for x86_64-efi platform.
Installation finished. No error reported.
```


# Install grub for bios
Again based on previous article. These grub files wasn't installed on my computer. I downloaded them from [debian][debian-i386grubpc] and unpacked them into directory and used --directory parameter to refer to them. In case you will receive error message like "Attempting to install GRUB to a disk with multiple partition labels" you can try to use parameter --force. I found somewhere that this is probably a bug in grub. It interprets data in mbr to be overwritten and as a result sometimes message is displayed.
```
# grub-install --target=i386-pc --recheck --boot-directory=/mnt/usb/boot --directory=/home/toho/programs/grub/i386-pc  /dev/sdb
Installing for i386-pc platform.
Installation finished. No error reported.
```

USB stick is prepared. You only need to add proper grub.cfg config. I use [this config file] [tomas303-grubcfg] actually and all menu items work. Iso files are stored in subdirectory /boot/iso/. You can try this or whatsever you will find on internet.


# Links:

* [arch linux multiboot usb drive][archlinux-multibootusb]
* [download debian i386 grub pc package][debian-i386grubpc]
* [great source of information about many bootloaders][rodsbooks-bootloaders]
* [heap of live iso boot grub config files][LiveISOFarm]
* [This helped me to solve boot Opensuse tumbleweed live boot][TumbleweedLiveBootProblem]


[archlinux-multibootusb]: https://wiki.archlinux.org/index.php/Multiboot_USB_drive
[debian-i386grubpc]: https://packages.debian.org/sid/i386/grub-pc-bin/download
[tomas303-grubcfg]: https://github.com/tomas303/bootconf/blob/master/grub.cfg
[rodsbooks-bootloaders]: http://rodsbooks.com/efi-bootloaders/
[LiveISOFarm]: http://trcmdisk01.tripod.com/linux/s_mmlf01.html
[TumbleweedLiveBootProblem]: https://groups.google.com/forum/#!topic/kiwi-images/ZJwK8k-tUpQ


