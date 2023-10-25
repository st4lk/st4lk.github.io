---
layout: post
title:  "Скрипт для скачивания музыки вконтакте"
date:   2013-02-04 18:19:43 +0000
categories: api free python
redirect_from:
  - /2013/script-downloading-music-vkcom-vkontakteru/
  - /blog/2013/02/04/script-downloading-music-vkcom-vkontakteru.html
---

<div class="gist-wrp"><div class="github-btn" id="github-btn" style="float:right;"> <a class="gh-btn" id="gh-btn" href="https://gist.github.com/st4lk/4708673" target="_blank"> <span class="gh-ico"></span> <span class="gh-text" id="gh-text">Gist</span> </a></div></div>

[![Скрипт для скачивания музыки вконтакте](/assets/images/posts/2013-02-04-script-downloading-music-vkcom-vkontakteru/vk_audio.jpeg "Скрипт для скачивания музыки вконтакте")]({{ site.baseurl }}{{ page.url }})

Беглый поиск соответствующего скрипта на python'е не дал результов. В [статье](http://habrahabr.ru/post/143860/) на хабре ссылка не работает. Решил написать свой велосипед, он доступен [здесь](https://gist.github.com/4708673).

Запуск (нужен установленный [python интерпретатор](http://www.python.org/download/releases/2.7.4/)):

```bash
python vkcom_audio_download.py
```

Проверял на python 2.6 и 2.7. Никаких дополнительных библиотек не требуется.

<!--more-->

### Принцип работы

Скрипт проверяет сохраненный access_token. Если его нет или срок истек, то открывается страница в браузере с запросом на доступ к данным аккаунта (аудио записям). После подтверждения идет редирект на h[ttps://oauth.vk.com/blank.htm#](https://oauth.vk.com/blank.htm#)... . Нужно скопировать весь url, на который вас редиректнуло и вставить его в консоль скрипта. Далее будут скачиваться все ваши аудиозаписи. Если аудиозапись уже есть на диске - то скачивания не происходит.

Будут запрошены ваши данные приложением с app_id = 3358129. Можно создать свое Standalone-приложение с доступом к аудио здесь: [http://vk.com/editapp?act=create](http://vk.com/editapp?act=create). И заменить APP_ID на ваше.

Ссылка на скрипт: [https://gist.github.com/4708673](https://gist.github.com/4708673).

Код скрипта:

<script src="https://gist.github.com/st4lk/4708673.js"></script>
