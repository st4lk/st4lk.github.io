---
layout: post
title:  "Задание url для обработчиков Tornado"
date:   2014-12-15 18:19:43 +0000
categories: tornado
redirect_from:
  - /2014/set-url-for-tornado-handlers/
  - /blog/2014/12/15/set-url-for-tornado-handlers.html
---

[![Задание url для обработчиков Tornado](https://img-fotki.yandex.ru/get/17846/85893628.c66/0_1644bf_5c58d342_L.png "Задание url для обработчиков Tornado")]({{ site.baseurl }}{{ page.url }})


В tornado, для привязки обработчиков к url'ам, можно передать список из кортежей `(url regex, handler)` при инициализации приложения:

```python
application = tornado.web.Application([
    (r"/", MainHandler),
    (r"/some/path/page/(?P<pk>[0-9]+)$", PageHandler),
])
```

Но не секрет, что гораздо удобнее использовать обертку [`tornado.web.url`](http://www.tornadoweb.org/en/stable/web.html?highlight=url#tornado.web.URLSpec), которая позволяет присваивать имена для путей (похожа на [django'вский url](https://docs.djangoproject.com/en/dev/ref/urls/#django.conf.urls.url)).

<!--more-->

Однако, в паре рабочих проектах, с которыми приходилось работать, эта обертка не использовалась. А так же в некоторых примерах из tornado документации ([раз](http://www.tornadoweb.org/en/stable/index.html#hello-world), [два](http://www.tornadoweb.org/en/stable/guide/templates.html#ui-modules), [три](http://www.tornadoweb.org/en/stable/guide/security.html#cookies-and-secure-cookies)) тоже используются обычные кортежи, без url, что может сбить с толку. Поэтому считаю полезным описать те преимущества, которые дает эта обертка.

Итак, какие неудобства мы испытываем при работе **без** использования url.

## Без url()

Чтобы в коде или в шаблоне воспроизвести нужный путь, приходится вручную вводить строку.

Пример

**app.py**:

```python
import tornado.ioloop
import tornado.web

class MainHandler(tornado.web.RequestHandler):
    def get(self):
        self.render("home.html", title="My title", pages=[1, 2, 3])

class PageHandler(tornado.web.RequestHandler):
    def get(self, page_n):
        email_text = "Please visit this page: '/some/path/page/{page_n}/'".format(
            page_n=1)
        send_email('some@person.com', email_text)
        self.render("page.html", title="Page", page_n=page_n)

application = tornado.web.Application([
    (r"/", MainHandler),
    (r"/some/path/page/(?P<page_n>[0-9]+)/$", PageHandler),
])

if __name__ == "__main__":
    application.listen(8888)
    tornado.ioloop.IOLoop.instance().start()
```

**home.htm**:

{% raw %}
```python
<html>
   <head>
      <title>{{ title }}</title>
   </head>
   <body>
     <div>View pages:</div>
     <ul>
       {% for page_n in pages %}
         <li><a href="/some/path/page/{{ page_n }}/">{{ page_n }}</a></li>
       {% end %}
     </ul>
   </body>
 </html>
```
{% endraw %}

**page.html**:

{% raw %}
```python
<html>
   <head>
      <title>{{ title }}</title>
   </head>
   <body>
     <div>You are viewing page #{{ page_n }}</div>
     <div>Back to <a href="/">Home<a></div>
   </body>
 </html>
```
{% endraw %}

Видим, что даже в этом простом коде пришлось трижды повторять путь `/some/path/page/`. А если нам понадобится чуть-чуть изменить эту строку? Придется делать автозамену, что неудобно и чревато ошибками. К тому же, некоторые пути могут быть громоздкими, что ухудшает читабельность кода.

## Используя url()

Этот же пример, но с оберткой `url`:

**app.py**:

```python
import tornado.ioloop
import tornado.web
from tornado.web import url


class MainHandler(tornado.web.RequestHandler):
    def get(self):
        self.render("home.html", title="My title", pages=[1, 2, 3])


class PageHandler(tornado.web.RequestHandler):
    def get(self, page_n):
        email_text = "Please visit this page: '{url}'".format(
            url=self.reverse_url('page', 1))
        send_email('some@person.com', email_text)
        self.render("page.html", title="Page", page_n=page_n)


application = tornado.web.Application([
    url(r"/", MainHandler, name="home"),
    url(r"/some/path/page/(?P<page_n>[0-9]+)/$", PageHandler, name="page"),
])

if __name__ == "__main__":
    application.listen(8888)
    tornado.ioloop.IOLoop.instance().start()
```

**home.html**:

{% raw %}
```html
<html>
   <head>
      <title>{{ title }}</title>
   </head>
   <body>
     <div>View pages:</div>
     <ul>
       {% for page_n in pages %}
         <li><a href="{{reverse_url('page', page_n)}}">{{ page_n }}</a></li>
       {% end %}
     </ul>
   </body>
 </html>
```
{% endraw %}

**page.html**:

{% raw %}
```html
<html>
   <head>
      <title>{{ title }}</title>
   </head>
   <body>
     <div>You are viewing page #{{ page_n }}</div>
     <div>Back to <a href="{{reverse_url('home')}}">Home<a></div>
   </body>
 </html>
```
{% endraw %}

Путям присвоены значащие имена, которые используются для воспроизведения url'a с помощью метода [`reverse_url`](http://www.tornadoweb.org/en/stable/web.html?highlight=url#tornado.web.Application.reverse_url). Если нам нужно будет подправить какой-либо путь, то мы сделаем это лишь в одном месте. Гораздо удобнее!
