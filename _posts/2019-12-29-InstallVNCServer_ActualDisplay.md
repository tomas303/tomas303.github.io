---
layout: post
title:  "install VNC server to share actual display"
date:   2019-12-29 20:00:00
categories: samba
---
I needed to install VNC server inside docker image, so I made a bit of exploring around and found [start vnc scraping][startvnc-scraping]. Under scraping server is understood x0vncserver which don't create virtual display but shares existing X server display. So it is ideal for use inside docker image.

Installation run without any problem:
{% highlight bash %}
apt-get install tigervnc-scraping-server
{% endhighlight %}

I wanted to connect without password. You can do this by SecurityTypes parameter as described in [x0vncserver manual][x0vncserver-manual]. I put this info and info about running vnc server in background  from previous link and that's it:

{% highlight bash %}
x0vncserver SecurityTypes=None >/dev/null 2>&1 &
{% endhighlight %}

I tested it all under debian lxqt installation.


# Links:
* [start vnc scraping][startvnc-scraping]
* [x0vncserver manual][x0vncserver-manual]


[startvnc-scraping]: https://www.howtoforge.com/tutorial/how-to-start-a-vnc-server-for-the-actual-display-scraping-with-tigervnc
[x0vncserver-manual]:https://tigervnc.org/doc/x0vncserver.html