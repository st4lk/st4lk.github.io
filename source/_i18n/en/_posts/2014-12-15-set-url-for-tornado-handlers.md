---
layout: post
title:  "Set url for Tornado handlers"
date:   2014-12-15 18:19:43 +0000
categories: tornado
redirect_from:
  - /2014/set-url-for-tornado-handlers/
---

[![Set url for Tornado handlers](https://img-fotki.yandex.ru/get/17846/85893628.c66/0_1644bf_5c58d342_L.png "Set url for Tornado handlers")]({{ site.baseurl }}{{ page.url }})


To set url for tornado handlers we can pass list of tuples `(url regex, handler)` into application initialisation:

```python
application = tornado.web.Application([
    (r"/", MainHandler),
    (r"/some/path/page/(?P<pk>[0-9]+)$", PageHandler),
])
```

But it is more convenient to use wrapper [`tornado.web.url`](http://www.tornadoweb.org/en/stable/web.html?highlight=url#tornado.web.URLSpec), that allows to assign meaningful names for paths (similar to [django url](https://docs.djangoproject.com/en/dev/ref/urls/#django.conf.urls.url)).

<!--more-->


Nevertheless, in a couple of production projects that i had to work with, this wrapper wasn't used. Also in some tornado examples from documentation ([one](http://www.tornadoweb.org/en/stable/index.html#hello-world), [two](http://www.tornadoweb.org/en/stable/guide/templates.html#ui-modules), [three](http://www.tornadoweb.org/en/stable/guide/security.html#cookies-and-secure-cookies)) simple tuples are used, that can be confusing. So i think that it is worth to mention the advantages, that gives url wrapper.

So, what disadvantages we'll face in case of tuples, i.e. **without** using a url.

## Without url()

To represent needed path in code or in template, we have to manually enter the string.

Example.

```python
**app.py**:

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
```html
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
{% endraw %}
```

**page.html**:
{% raw %}
```html
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

As we can see, even in this simple code we repeat path `/some/path/page/` three times. What if we'll need to change this string a little? We'll have to make an autocorrect, that is uncomfortably and can lead to errors. Furthermore, some paths can be cumbersome and decrease code readability.

## With url()

Same example, but with `url`:

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

Paths now have meaningful names that are used in url representation by method [`reverse_url`](http://www.tornadoweb.org/en/stable/web.html?highlight=url#tornado.web.Application.reverse_url). If it is needed to change some path, we'll do it in one single place. Much more convenient!
