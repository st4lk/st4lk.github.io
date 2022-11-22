---
layout: post
title:  "Tornado and pgettext"
date:   2015-06-05 18:19:43 +0000
categories: i18n tornado
redirect_from:
  - /2015/tornado-and-pgettext/
---

[![Tornado and pgettext](https://img-fotki.yandex.ru/get/15560/85893628.c68/0_18816d_971d97b2_L.png "Tornado and pgettext")]({{ site.baseurl }}{{ page.url }})

Recently (26.05.2015) new [tornado 4.2](http://www.tornadoweb.org/en/latest/releases/v4.2.0.html) was released. It contains different updates, the most valuable i suppose are modules tornado.locks and tornado.queues. They migrated from package Toro, look detailed explanation in Jesse Jiryu Davis [post](http://emptysqua.re/blog/tornado-locks-and-queues/).

Here i want to tell about another helpful function, that was added with my help - [pgettext](http://www.tornadoweb.org/en/latest/locale.html#tornado.locale.GettextLocale.pgettext).

<!--more-->

It can be useful, when you are creating the translation for ambiguous strings. Let's say we have word "bat" and we want to show it either in english, either in russian, depending on user's preferred language. Special translate functions can be used to implement it.

For example in html template:

{% raw %}
```html
<div>{{_("Bat")}}</div>
```
{% endraw %}

Next we'll use util xgettext to create translation file, that will contain something like this (details of i18n process can be found [here]({{ site.baseurl }}/i18n/async/tornado/2015/01/31/tornado-internationalization-and-localization.html))

```html
msgid "Bat"
msgstr ""
```

So now in place of empty string we need to put a translation. But what does the word "Bat" mean? Is it a mammal or a club? It will be very hard for translator to understand exact meaning without knowing the context.

That's where function pgettext will help, it accept context as the first argument:

{% raw %}
```html
<div>{{ pgettext("mammal", "Bat") }}</div>
```
{% endraw %}

To generate translations add following options to xgettext:

--keyword=pgettext:1c,2 --keyword=pgettext:1c,2,3

After that translation will look like this:

```
msgctxt "mammal"
msgid "Bat"
msgstr ""
```

Now it is clear what was meant and we can translate definitely:

```
msgctxt "mammal"
msgid "Bat"
msgstr "Летучая мышь"
```

Plural forms are also supported:

{% raw %}
```html
<div>{{ pgettext("mammal", "Bat", "Bats", 2) }}</div>
```
{% endraw %}

Python code example:

```python
class HomeHandler(tornado.web.RequestHandler):

    def get(self):
        self.render("home.html", text=self.locale.pgettext("mammal", "Bat", "Bats", 2))
```

Plural form translations:

```
msgctxt "mammal"
msgid "Bat"
msgid_plural "Bats"
msgstr[0] "Летучая мышь"
msgstr[1] "Летучие мыши"
msgstr[2] "Летучих мышей"
```
