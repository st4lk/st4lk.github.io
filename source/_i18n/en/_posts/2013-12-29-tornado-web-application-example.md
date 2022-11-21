---
layout: post
title:  "Tornado web application example"
date:   2013-12-29 18:19:43 +0000
categories: async tornado mongodb
redirect_from:
  - /2013/tornado-web-application-example/
---

<a class="github-button" href="https://github.com/st4lk/acl_webapp" data-icon="octicon-star" data-size="large" data-show-count="true" aria-label="Star st4lk/acl_webapp on GitHub">Star</a>

[![Tornado web application example](/assets/images/posts/2013-12-29-tornado-web-application-example/tornado.jpeg "Tornado web application example")]({{ site.baseurl }}{{ page.url }})

[Tornado](http://www.tornadoweb.org/) - async web framework for python. I'll cover shortly pros and cons about tornado and introduce typical web project, that is built on top of it.

By describing pros and cons i mean my own point of view in compare with django.

<!--more-->

### Tornado pros

#### 1. Asynchronous.

In tornado core there is a infinite loop called "ioloop", that listen for events. All that happens in one single thread. For example, somebody wants to fetch /home/ url. For that event `HomeHandler` is registered and ioloop will call it. The handler code is executing. What happens with ioloop? It is blocked now, until handler code is finished. If another user will fetch the url, he has to wait until previous request will be processed. What's the point then? There is a mechanism of callbacks. For long task processing we ask: do that hard operation (db access, or external http fetch) and when you'll finish, call this callback please to let me know. For know, go ahead. Ioloop continue to process other events. At some time, our long task will be finished and corresponding event will be raised and registered callback will be called. But keep in mind, that functions itself must be async. Operation like `time.sleep(10)` will block ioloop anyway, even if it is called as async function. So for async operations special functions and libraries are used.

But anyway, what benefits gives async style with only one started thread? Why it is bad to create new process or thread for each new request?

Because process and even thread is expensive in terms of computer resources. Imagine that for each request we'll create new thread. Then, if 1000 users will access simultaneously, then we'll need to create 1000 threads! I suppose regular server can't afford it. Of course, we always can limit max number of threads. In this case new user have to wait until some thread will be freed.

Lets imagine more interesting task - online chat. When somebody writes message, all members must see it. What solutions comes to mind for django? For example, every member will send ajax request every 5 seconds to get new messages. This will eat server resources very quickly in case of big amount of chat members. For each ajax request it is needed to open and close connection, spawn new thread. It cost a lot. Another variant will be keep-alive http requests, when we hold connection without closing. But it is a [C10K](http://en.wikipedia.org/wiki/C10k_problem) problem. At some time it will be needed to spawn 10k thread (or even more).

That's where async solutions will help. It is possible to use [WebSockets](http://en.wikipedia.org/wiki/WebSocket) or http request with keep-alive. In async frameworks such requests will not eat all computer resources.

#### 2. WebSocket

In some way it is a result of async. Look [here](http://en.wikipedia.org/wiki/WebSocket) for websocket description.

#### 3. Less ORM and html-template dependency

For example django's built-in ORM works only with SQL databases. If you want to connect to mongodb, you'll probably can't use third party applications, that are linked to django's ORM. Also some built-in apps, for example admin. You'll face same situation, if you want to use SQLAlchemy instead of django's ORM.

Many apps are using django's template system. Want to use Jinja2? Well, then adopt all this apps for it!

Tornado has less problems with that. But at the same time tornado doesn't have such ready applications as django does. So you'll have to write some tools manually anyway (admin, hello). Also, not all database drivers has async support. Currently i know async drivers for mongodb, postgresql. Not sure about mysql.

### Tornado cons

#### 1. Less popularity than django.

It means, that you'll have to write many things by yourself, whereas django has third-party apps. For example, admin.

#### 2. Code complexity.

Async code is a little bit harder to read and write. So it is harder to start working with tornado, that with django.

### Typical project example for tornado

Here [https://github.com/st4lk/acl_webapp](https://github.com/st4lk/acl_webapp).

It is an [ACL](http://en.wikipedia.org/wiki/Access_control_list) application, i.e. application with access rights. Rights are based on models: every user have field permissions:

```python
permissions = {
    'model_name_1': ['read',],
    'model_name_2': ['read', 'write'],
    'model_name_3': ['read', 'write', 'delete'],
}
```

In this case user has rights "read only" for model 'model_name_1', "read and write" for 'model_name_2" and "read, write and delete" for model_name_3.

Project follows django structure: it has applications, each of them solves some certain task. Here are app examples:

```python
accounts
news
pages
```
and so on.

Each application contains models, handlers, forms.

Base handlers:

- ListHandler
- DetailHandler
- CreateHandler
- DeleteHandler
- and so on, as in django

All settings are defined in `settings.py`.

### Used technologies
- [mongodb](http://www.mongodb.org/) (database)
- [motor](http://motor.readthedocs.org/en/stable/) (async driver for DB)
- [schematics](http://schematics.readthedocs.org/en/latest/) (abstract models for DB)
- [WTForms](http://wtforms.readthedocs.org/en/latest/) (forms)
- [Jinja2](http://jinja.pocoo.org/docs/) (html templates)

P.S. It is possible, that i've made a mistake in tornado describing and understanding. I'll be glad to read it in comments!
