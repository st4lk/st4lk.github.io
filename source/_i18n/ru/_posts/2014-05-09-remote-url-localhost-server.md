---
layout: post
title:  "Внешний url для localhost сервера"
date:   2014-05-09 18:19:43 +0000
categories: deploy free
redirect_from:
  - /2014/remote-url-localhost-server/
---

[![Внешний url для localhost сервера](/assets/images/posts/2014-05-09-remote-url-localhost-server/ngrok_logo.jpeg "Внешний url для localhost сервера")]({{ site.baseurl }}{{ page.url }})

Есть замечательная тулза под названием [ngrok](https://ngrok.com/). Она позволяет привязать URL для вашего localhost сервера!

<!--more-->

Например, вы запускаете тестовый сервер django у себя на компьютере:

```bash
  python manage.py runserver
```

и этот сервер будет доступен через внешний URL.

### Для чего?

Как минимум есть такие задачи:

- продемонстрировать проект заказчику
- проверить интеграцию вашего сайта с платежной системой, которая отправляет уведомления. Например paypal, где для получения [IPN](https://developer.paypal.com/webapps/developer/docs/classic/products/instant-payment-notification/) сообщения нужен работающий URL, даже в sandbox

### Как

- Скачиваем ngrok [отсюда](https://ngrok.com/download)
- Распаковываем скаченный архив
- Запускаем тестовый django сервер (по умолчанию это 8000 порт)
- Запускаем ngrok:
  ```bash
  ./ngrok 8000
  ```


- В коносле видим примерно следующее:
  ```bash
  ngrok

  Tunnel Status                 online
  Version                       1.6/1.6
  Forwarding                    http://51c85c8a.ngrok.com -> 127.0.0.1:8000
  Forwarding                    https://51c85c8a.ngrok.com -> 127.0.0.1:8000
  Web Interface                 127.0.0.1:4040
  # Conn                        0
  Avg Conn Time                 0.00ms
  ```

Теперь заходим по адресу http://51c85c8a.ngrok.com и видим наш сервер!

### Улучшения

Не совсем удобно, что при каждом запуске ngrok будет присваивать новый url вида `********.ngrok.com`.

Но можно присвоить свой поддомен и сервер будет доступен по этому адресу.

Для этого надо лишь:

- [зарегистрироваться](https://ngrok.com/user/signup)
- получить auth token
- один раз указать ngrok полученный auth token (после первого запуска создается файл `~/.ngrok`, в котором сохраняется введенный token):

  ```bash
  ./ngrok -authtoken your_auth_token 8000
  ```

- теперь можно запускать так:

  ```bash
  ./ngrok  -subdomain=mysupersite 8000
  ```

Теперь наш локальный сервер доступен по адресу http://mysupersite.ngrok.com
