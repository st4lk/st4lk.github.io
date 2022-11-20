---
layout: post
title:  "MobileESP: Скрипт определения мобильного устройства посетителя"
date:   2012-11-29 18:19:43 +0000
categories: django python
redirect_from:
  - /2012/mobileesp-easily-detect-mobile-web-site-visitors/
---

Скрипт полезен, если вы хотите показывать разные версии сайта для обычных компьютеров и мобильных устройств. Большое количество методов для определения вида девайса. Доступен на разных языках программирования, включая python. Собственно порт на python был написан мной по просьбе freelance заказчика.

<!--more-->

Так его можно использовать в django проекте:

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

Сам скрипт на [code.google.com](http://code.google.com/p/mobileesp/source/browse/Python/mdetect.py), ко всем методам есть комментарий-описание.

Описание на [сайте проекта](http://blog.mobileesp.com/?cat=10).
