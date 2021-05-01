---
layout: post
title:  "Printer and scanner M2979W"
date:   2021-05-01 12:00:00
categories: scanner samsung
---
I have wireless printer with scanner samsung m2070w . Linux driver stopped working some time ago. Printing was still possible but scan didn't work. I tried lot of things I had found on net.  Finally I had found [sane-airscan] and once installed it just worked. It is really good project and supports plenty devices.

On linux mint is available as sane-airscan package.

```bash
apt install sane-airscan
```

# Links:
* [sane-airscan][sane-airscan]

[sane-airscan]: https://github.com/alexpevzner/sane-airscan
