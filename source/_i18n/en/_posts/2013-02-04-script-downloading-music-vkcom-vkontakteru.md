---
layout: post
title:  "Script for downloading music from vkontakte"
date:   2013-02-04 18:19:43 +0000
categories: api free python
redirect_from:
  - /2013/script-downloading-music-vkcom-vkontakteru/
---

[![Script for downloading music from vkontakte](/assets/posts/2013-02-04-script-downloading-music-vkcom-vkontakteru/vk_audio.jpeg "Script for downloading music from vkontakte")]({{ site.baseurl }}{{ page.url }})

A quick search of corresponding python script doesn't give results. In [post](http://habrahabr.ru/post/143860/) on habra link is broken. So i decided to write my own bicycle, it is avaliable [here](https://gist.github.com/4708673).

Launch (needs installed [python interpreter](http://www.python.org/download/releases/2.7.4/)):

```bash
python vkcom_audio_download.py
```

Tested on python 2.6 and 2.7. No external libraries required.

<!--more-->

### Algorithm

Script checks saved access_token. If it doesn't exists or expired, then page with authorisation is opened in browser. After confirmation you will be redirected to [https://oauth.vk.com/blank.htm#](https://oauth.vk.com/blank.htm#)... It is needed to copy this url and paste to script console. After that downloading is started. If audio track is present on disk - no downloading happens for it.

You account info will be requested by application with app_id = 3358129. It is possible to create your own Standalone-application with audio access at [http://vk.com/editapp?act=create](http://vk.com/editapp?act=create). And replace APP_ID with yours.

**Script avaliable here**: [https://gist.github.com/4708673](https://gist.github.com/4708673).

Script code:

<script src="https://gist.github.com/st4lk/4708673.js"></script>
