---
layout: post
title:  "Tornado and pgettext"
date:   2015-06-05 18:19:43 +0000
categories: i18n tornado
redirect_from:
  - /2015/tornado-and-pgettext/
---

[![Tornado and pgettext](https://img-fotki.yandex.ru/get/15560/85893628.c68/0_18816d_971d97b2_L.png "Tornado and pgettext")]({{ site.baseurl }}{{ page.url }})

Недавно (26 мая 2015 года) вышел релиз [tornado 4.2](http://www.tornadoweb.org/en/latest/releases/v4.2.0.html). В него вошли разные дополнения, пожалуй основные из них - модули tornado.locks и tornado.queues. Они перекочевали из пакета Toro, подробное описание процесса от Jesse Jiryu Davis в его [блоге](http://emptysqua.re/blog/tornado-locks-and-queues/).

Здесь же хочу рассказать о другой маленькой функции, которая была добавлена с моей помощью - [pgettext](http://www.tornadoweb.org/en/latest/locale.html#tornado.locale.GettextLocale.pgettext).

<!--more-->

Она может быть полезна, когда вы создаете перевод для неоднозначных строк. Допустим есть слово "bat", которое нужно вывести либо на английском, либо на русском, в зависимости от языка пользователя. Для этого можно воспользоваться соответствующими функциями перевода.

Например так (html шаблон):

{% raw %}
```html
<div>{{_("Bat")}}</div>
```
{% endraw %}

Далее мы с помощью утилиты xgettext создадим файл перевода, в котором будет что-то такое (подробно про процесс i18n можно почитать [тут]({{ site.baseurl }}/i18n/async/tornado/2015/01/31/tornado-internationalization-and-localization.html))

```html
msgid "Bat"
msgstr ""
```

Теперь на месте пустой строки нам нужно вставить перевод. Но что означает слово "Bat"? В английском языке это слово может означать "летучая мышь", а может "дубина", в зависимости от контекста. Переводчику будет очень трудно понять, что же имелось в виду.

Вот где пригодится функция pgettext, ей в качестве первого аргумента передается контекст фразы:

{% raw %}
```html
<div>{{ pgettext("mammal", "Bat") }}</div>
```
{% endraw %}

При генерации перевода нужно дополнительно указать такие опции для утилиты xgettext:

```bash
--keyword=pgettext:1c,2 --keyword=pgettext:1c,2,3
```

После этого файл перевода будет выглядеть так:

```
msgctxt "mammal"
msgid "Bat"
msgstr ""
```

Переводчик поймет, что в данном случае имелась в виду именно летучая мышь, поэтому перевод однозначен:

```
msgctxt "mammal"
msgid "Bat"
msgstr "Летучая мышь"
```

Множественные формы так же поддерживаются:

{% raw %}
```html
<div>{{ pgettext("mammal", "Bat", "Bats", 2) }}</div>
```
{% endraw %}

В python коде (не в шаблоне) это будет выглядеть так:

```python
class HomeHandler(tornado.web.RequestHandler):

    def get(self):
        self.render("home.html", text=self.locale.pgettext("mammal", "Bat", "Bats", 2))
```

Сам перевод множественных значений:

```
msgctxt "mammal"
msgid "Bat"
msgid_plural "Bats"
msgstr[0] "Летучая мышь"
msgstr[1] "Летучие мыши"
msgstr[2] "Летучих мышей"
```
