---
layout: post
title:  "Aphorism messenger"
date:   2012-08-31 18:19:43 +0000
categories: api java
redirect_from:
  - /2012/aphorism-messager/
---

[![Aphorism messenger](/assets/posts/aphorism-messenger/owl_48x48.png)]({{ site.baseurl }}{{ page.url }})

I have an interesting project I want to tell you about. The idea to create it was born when I was learning Java. I have read couple of books, made some small task programs but I would like to create something bigger.
<!--more-->

### Project summary

Desktop program (client), that lives in a tray and periodically shows aphorisms. It takes aphorisms from web-service (server), so data base with aphorisms lives in one place and it doesn't attached with each client. Aphorims have rating - it is amount of likes. When pop-up window with quotation arrives, user sees its rating and can edit it by giving or remove likes. Along with aphorism in the window there is an author. User can click it and look for an author biography. Also, there is an ability to look for your favorite aphorisms and list of top favorite aphorisms.

The result ([download, only in russian](https://sourceforge.net/projects/bwtclient/)):

![Aphorism example](/assets/posts/aphorism-messenger/just-aphorism.png)

Full project (client and server) is written in Java. Server hosts at **google app engine**, provides resources in xml format. It is a REST web service, so it can be used in many ways, for example for web site. Specification is avaliable [here](https://bestwisethoughts.appspot.com/).


Here is an example of resource: [show random aphorism](https://bestwisethoughts.appspot.com/1.0/thought/get/random).


Links:

- [detailed description of project (russian)](http://freehabr.ru/blog/gotome/2104.html)
- [client program](http://sourceforge.net/projects/bwtclient/)
- [server](http://bestwisethoughts.appspot.com/)
- [client source](http://sourceforge.net/p/bwtclient/code/)
- [server source](http://sourceforge.net/p/bwtserver/code/)
- [video review](http://www.youtube.com/watch?v=AIJywgQKatY)
