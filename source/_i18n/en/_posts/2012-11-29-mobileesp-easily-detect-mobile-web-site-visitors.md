---
layout: post
title:  "MobileESP: Easily detect mobile web site visitors"
date:   2012-11-29 18:19:43 +0000
categories: django python
redirect_from:
  - /2012/mobileesp-easily-detect-mobile-web-site-visitors/
  - /blog/2012/11/29/mobileesp-easily-detect-mobile-web-site-visitors.html
---

Script will be useful, if you want to show different version of site for desktop computers and mobile devices. Big variety of methods to detect mobile type. Avaliable in different languages, including python. The port to python was made by me with help from my freelance customer.

<!--more-->

Here how it can be used in django project:

```python
from mobileesp import mdetect

user_agent = request.META.get("HTTP_USER_AGENT")
http_accept = request.META.get("HTTP_ACCEPT")
if user_agent and http_accept:
    agent = mdetect.UAgentInfo(userAgent=user_agent, httpAccept=http_accept)
    #Do first! For iPhone, Android, Windows Phone 7, etc.
    if agent.detectTierIphone():
        HttpResponseRedirect('/myapp/i/')
    #Then catch all other mobile devices
    if agent.detectMobileQuick():
        HttpResponseRedirect('/myapp/m/')
#For traditional computers and tablets (iPad, Android, etc.)
return HttpResponseRedirect('/myapp/d/')
```

Script on [code.google.com](http://code.google.com/p/mobileesp/source/browse/Python/mdetect.py), all methods have comments with description.

Description at [project site](http://blog.mobileesp.com/?cat=10).
