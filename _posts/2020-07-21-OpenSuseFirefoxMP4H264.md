---
layout: post
title:  "openSUSE MP4/H.264 codec and firefox"
date:   2020-07-21 12:00:00
categories: firefox codec mp4 h264
---

If firefox cannot play video it can be due to missing codecs. It is always good to start from determining a reason of problem and Firefox web console is right tool here (main menu / Web Developer / Web Console). I am using openSUSE and in my case h264 was missing. You can verify it using [html5test] too. I found nice related info what helped me to solve problem on [Firefox_MP4/H.264_Video_Support].

I had used Packman repository - even when I am using tumbleweed - and installed every libavcodec, libavformat, libavdevice I found in actual repositories:

{% highlight cmd %}
zypper in libavcodec56 libavcodec57 libavcodec58_91 libavformat56 libavformat57 libavformat58_45 libavdevice56 libavdevice57 libavdevice58_10
{% endhighlight cmd %}


More info about installed packages can be found using -s (show details) and -i (only installed packages) switches:

{% highlight cmd %}
zypper se -si libavformat

S  | Name             | Summary                        | Type
---+------------------+--------------------------------+--------
i+ | libavformat56    | FFmpeg's stream format library | package
i+ | libavformat57    | FFmpeg's stream format library | package
i  | libavformat58_45 | FFmpeg's stream format library | package
{% endhighlight cmd %}

Btw i and i+  in first column means:

i+      installed by user request

i       installed automatically (by the resolver, see section Automatically installed packages)




* [Firefox_MP4/H.264_Video_Support]
* [html5test]

[Firefox_MP4/H.264_Video_Support]: https://en.opensuse.org/SDB:Firefox_MP4/H.264_Video_Support
[html5test]: https://html5test.com/