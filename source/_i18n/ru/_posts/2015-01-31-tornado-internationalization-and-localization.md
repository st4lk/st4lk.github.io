---
layout: post
title:  "Tornado i18n и l10n"
date:   2015-01-31 18:19:43 +0000
categories: i18n async tornado
redirect_from:
  - /2015/tornado-internationalization-and-localization/
---

<a class="github-button" href="https://github.com/st4lk/tornado_i18n_example" data-color-scheme="no-preference: light; light: light; dark: dark;" data-icon="octicon-star" data-size="large" data-show-count="true" aria-label="Star st4lk/tornado_i18n_example on GitHub">Star</a>

[![Tornado i18n и l10n](https://img-fotki.yandex.ru/get/4/85893628.c67/0_1715c7_738478c6_orig.png "Tornado i18n и l10n")]({{ site.baseurl }}{{ page.url }})

Статья о том, что такое i18n и i10n и как это реализовать в приложении на [tornado](http://www.tornadoweb.org/en/stable/). Получилось довольно много букв, но хотелось рассказать доступно обо всем процессе. Сама пошаговая инструкция - во второй половине статьи.

<!--more-->

Общие определения
------------------

#### i18n

i18n - сокращение от internationalization. Так называют процесс поддержки разных языков в приложении. Это не сам перевод, а именно техническая составляющая проекта, которая позволяет отображать текст на разных языках, в зависимости от предпочтений пользователя. Обычно реализацией занимается разработчик.

#### l10n

l10n - сокращение от localization. Означает сам процесс перевода текста на нужные языки. Обычно реализацией занимается переводчик.

#### Языковые теги (language tags)

Языковые теги ([language tags](http://www.w3.org/International/articles/language-tags/)) указывают язык текста. Формат тегов содержит много нюансов, все они определены в [rfc5646](http://www.rfc-editor.org/rfc/rfc5646.txt).
Но наиболее часто встречающийся такой:

```
en-US
```

Первая часть означает язык, вторая - регион применения. В данном случае тег `en-US` означает английский язык, которым пользуются в США. А скажем `en-GB` будет означать ангийский, которым пользуются в Англии (я полагаю, эти языки имеют небольшие различия). В языковом теге только одна часть обязательная - это язык. Т.е. это абсолютно нормальный тег:

```
en
```

Более того, когда нет особой надобности указывать регион - не указывайте его.

#### CLDR

[CLDR](http://cldr.unicode.org/) - Common Locale Data Repository (общее хранилище языковых данных).    
Содержит часто используемые данные на разных языках:

- формат даты, цены в разных валютах, временных зон
- название стран, дней недели, месяцев
- правила написания чисел, формат множественного числа, направление письма, первый день недели
- и много всего другого

gettext<a name="gettext"></a>
------
[gettext](https://www.gnu.org/software/gettext/) - библиотека для реализации процесса i18n. В этой статье описывается работа именно с ней.   
 
Tornado поддерживает так же работу и с [CSV файлам](http://www.tornadoweb.org/en/stable/locale.html#tornado.locale.load_translations), но этот способ имеет гораздо меньше возможностей, поэтому его рассматривать не будем.

#### Краткий принцип работы с gettext
1. Все текстовые строки в коде пишем на английском.
2. Все строки подставляем в виде аргумента одной из специальных функций, реализованных в gettext. Обычно в python'е для такого случая используют функцию с именем `_`.    
    Было:
    ```bash
    "Hello world!"
    ```
    Стало:

    ```bash
    _("Hello world!")
    ```

3. Создаем шаблонный файл `.pot` для перевода текста.    
    Это делается с помощью команды [xgettext](https://www.gnu.org/software/gettext/manual/html_node/xgettext-Invocation.html#xgettext-Invocation). Она парсит указанные файлы, находит в них вызов той самой функции `_` и генерирует файл _messages.pot_.    
    В этом файле, помимо некоторых служебных данных (заголовков), будут содержаться строки, требующие перевода:    
    ```bash
    msgid "Hello world!"
    msgstr ""
    ```
    Этот файл не нужно редактировать, пусть он всегда будет таким. В принципе, особой нужды в этом файле нет, непосредственно в переводе он не задействован. Например скрипты django для перевода его нигде не сохраняют. Но все же лучше оставить, ведь его всегда можно дать переводчику, чтобы он мог оценить объем работы.

4. Создаем файл перевода на конкретном языке.

    Для этого воспользуемся командой [msginit](https://www.gnu.org/software/gettext/manual/html_node/msginit-Invocation.html), которая из шаблона _messages.pot_ создаст новый файл _messages.po_. По сути, это будет копия нашего шаблона, за исключением некоторых частей, специфичных для выбранного языка.

5. Переводим строки в нашем новом _messages.po_, а так же заполняем заголовки нашими данными. Перевод будет выглядеть так:

    ```bash
    msgid "Hello world!"
    msgstr "Привет, мир!"
    ```

6. Компилируем перевод командой [msgfmt](https://www.gnu.org/software/gettext/manual/html_node/msgfmt-Invocation.html). На выходе получаем _messages.mo_.

7. Если где-то в коде добавились строки, которые нужно переводить, то следует лишь обновить _messages.po_, а не создавать его заново.

    Таким образом старые переводы сохранятся. Для этого:    
    - опять создаем шаблон _.pot_ (пункт 3). Да, это перезатрет предыдущий _messages.pot_, но это не страшно, ведь мы там ничего не меняем сами
    - используем команду [msgmerge](https://www.gnu.org/software/gettext/manual/html_node/msgmerge-Invocation.html), которая синхронизирует файлы _.po_ и _.pot_
    - повторяем пункты 5 и 6.

Все, если функция `_` в нашем проекте работает правильно, то англичанин увидит текст "Hello world!", а русский - "Привет, мир!".

Пока осталось неясным, что из себя представляет эта самая функция `_` и откуда ее взять. Так же, как мы определим предпочитаемый язык пользователя, кто он - англичанин или русский? И где взять эти команды `xgettext`, `msginit`, `msgmerge`, `msgfmt`?

По порядку.

#### Функция `_`

Эту функцию можно написать самому, ведь в python уже встроена работа с [gettext](https://docs.python.org/2/library/gettext.html). Однако, в tornado и в django она уже определена. Надо лишь задать ей это имя. В django это выглядит так:

```python
from django.utils.translation import ugettext as _
_("Hello world!")
```

А в  tornado примерно так:

```python
class SomeHandler(tornado.web.RequestHandler):
    def get(self):
        _ = self.locale.translate
        _("Hello world!")
```

#### Как функция `_` определяет предпочитаемый язык пользователя?

В самом простом случае в веб приложении язык узнают из HTTP заголовка Accept-Language (предпочитаемый язык задается в настройках браузера). И в django и в tornado это уже реализовано.    
Для более сложной логики, когда например пользователь сам может задать нужный ему язык в настройках своего профиля на сайте, в обоих фреймворках есть соответствующие средства.   
Да, в отличие от django, tornado из коробки не умеет определять язык из префикса в url. Т.е. при правильной настройке django, запрос вида `/ru/.../` отобразит русский язык, а `/en/.../` - английский. Но tornado так не умеет, его этому нужно обучать вручную.


#### Где взять команды `xgettext`, `msginit`, `msgmerge`, `msgfmt`
Их нужно установить.

В некоторых версиях Ubuntu они доступны из коробки. Установить можно так:

```bash
sudo apt-get install gettext
```

На OSX:

```bash
brew install gettext
brew link gettext --force
```

Для windows бинарники можно скачать отсюда (не проверял):  [http://gnuwin32.sourceforge.net/packages/gettext.htm](http://gnuwin32.sourceforge.net/packages/gettext.htm)

Если устанавливать не хочется или нет возможности, то можно воспользоваться встроенными в python командами: [`pygettext.py`, `msgfmt.py`](https://docs.python.org/2/library/gettext.html#internationalizing-your-programs-and-modules). Но у них гораздо меньше возможностей, чем у xgettext. К тому же нет msgmerge, который крайне удобен.

Есть еще одно решение - библиотека [babel](http://babel.pocoo.org/). Она поддерживает многие функции xgettext, включая msgmerge. При этом не требует установленной xgettext, чистый питон. Расскажу о ней чуть позже.

Отличия tornado от django
-----------------------

Прежде чем приступать к инструкции по реализации i18n в tornado, хочу отметить одну особенность.    
Она крайне важна для понимания работы tornado в целом. 

Основное отличие tornado от django состоит в том, что tornado выполняется в одном процессе, а django - нет. Как это влияет на перевод строк?    
В django мы можем задать переводимые строки где угодно, хоть в моделях. Для этого в django есть понятие "ленивого" перевода, например [ugettext_lazy](https://docs.djangoproject.com/en/dev/topics/i18n/translation/#working-with-lazy-translation-objects):

```python
from django.db import models
from django.utils.translation import ugettext_lazy as _

class SomeModel(models.Model):
    title = models.CharField(_("Title"), max_length=50)
```

Функция `ugettext_lazy` возвращает строку не сразу, а в момент непосредственного обращения к ней. Только в тот момент, когда предпочитаемый язык уже будет определен. Но откуда она все-таки узнает этот язык?    
Очевидно, что первоначально клиент должен сделать какой-то запрос, из которого мы узнаем информацию о посетителе и определим его локализацию. В этот момент django сохранит найденный язык (с помощью функции [activate()](https://docs.djangoproject.com/en/dev/ref/utils/#django.utils.translation.activate)) в глобальную переменную для данного потока (thread). Напомню, что для обработки каждого запроса в django создается отдельный изолированный поток.    
Вот почему функция `ugettext_lazy` может быть использована где угодно, она отобразит текст на верном языке. Ей не нужно передавать никакие данные о запросе, их она узнает из глобальной переменной.

А в tornado так не получится, потому что тут нет изолированных потоков, поток всегда один. В этом и фишка асинхронности.    
Что может получится, если мы попытаемся реализовать "ленивый" перевод в tornado?    
Давайте рассмотрим простейший проект на tornado. Для реализации "ленивости" воспользуемся пакетом [speaklater](https://pypi.python.org/pypi/speaklater):

```python
import os.path
from threading import local
import tornado.web
from speaklater import make_lazy_gettext

_active = local()

def activate(current_locale):
    _active.value = current_locale

def gettext(s):
    return _active.value.translate(s)

_ = make_lazy_gettext(lambda: gettext)

class HiModel(object):
    hello = _("Hello, world!")

class DoneModel(object):
    done = _("Fuh, done")

class HomeHandler(tornado.web.RequestHandler):
    def prepare(self):
        super(HomeHandler, self).prepare()
        activate(self.locale)  # set globally locale from request

    @tornado.gen.coroutine
    def get(self):
        hello_model = HiModel()
        self.write(unicode(hello_model.hello))
        self.write("<br/>")
        done_model = DoneModel()
        self.write(unicode(done_model.done))
        self.write("<br/>")
        self.finish()


application = tornado.web.Application([
    tornado.web.url(r"/", HomeHandler, name='home'),
])

if __name__ == "__main__":
    application.listen(8888)
    project_folder = os.path.dirname(os.path.abspath(__file__))
    tornado.locale.load_gettext_translations(os.path.join(project_folder, 'locale'), 'messages')
    tornado.ioloop.IOLoop.instance().start()
```

Тут `HiModel` и `DoneModel` подразумевают какие-то модели, неважно какие. Главное, что у них есть переводимые строки.    
Файл перевода выглядит примерно так:

```bash
msgid "Hello, world!"
msgstr "Привет, мир!"

msgid "Fuh, done"
msgstr "Фух, вроде готово"
```

Запустим наш маленький сервер.    
Условимся, что в браузере "browser_en" в настройках стоит английский язык, а в браузере "browser_ru" - русский.

Откроем адрес [http://127.0.0.1:8888/](http://127.0.0.1:8888/) в browser_ru и увидим:

```
Привет, мир!
Фух, вроде готово
```
То же самое в browser_en:

```
Hello, world!
Fuh, done
```

Вроде все работает правильно. Но попробуем добавить асинхронную задачу. Для простоты воспользуемся [асинхронным таймером](http://tornado.readthedocs.org/en/latest/ioloop.html#tornado.ioloop.IOLoop.add_timeout):

```python
@tornado.gen.coroutine
def get(self):
    hello_model = HiModel()
    self.write(unicode(hello_model.hello))
    self.write("<br/>")
    io_loop = tornado.ioloop.IOLoop.instance()
    yield tornado.gen.Task(io_loop.add_timeout, timedelta(seconds=5))
    done_model = DoneModel()
    self.write(unicode(done_model.done))
    self.write("<br/>")
    self.finish()
```

Т.е. мы просто добавили эти строки:

```python
    io_loop = tornado.ioloop.IOLoop.instance()
    yield tornado.gen.Task(io_loop.add_timeout, timedelta(seconds=5))
```

между работой с `HiModel` и `DoneModel`.    
А теперь попробуем зайти из browser_ru и сразу, не дожидаясь окончания таймера, из browser_en.

В browser_ru мы увидим это:

```
Привет, мир!
Fuh, done
```

а в browser_en:

```
Hello, world!
Fuh, done
```

Думаю вы уже догадались, почему в browser_ru мы видим часть текста на русском, а часть - на английском. На всякий случай давайте разберемся.

В момент, когда было обращение из browser_ru, мы выставили глобально русский язык.    
Потом пошла асинхронная задача.    
Дальше пришел другой запрос (browser_en), который выставил глобально английский язык.    
После чего асинхронная команда из первого запроса завершилась и обработчик продолжил работу. Но язык уже поменялся другим обработчиком, и строка "Fuh, done" не перевелась.

Из всего этого можно сделать вывод, что в tornado определить язык можно только в контексте запроса  (handler), и никак иначе.


Реализация i18n в tornado с помощью xgettext <a name="tornado-i18n-xgettext"></a>
-----------------------------------------

В [документации tornado](http://www.tornadoweb.org/en/stable/locale.html#module-tornado.locale) процесс i18n описан довольно скудно, поэтому здесь хочу описать прям по шагам, что и как нужно делать.

По-моему, лучше всего объяснять на конкретном примере. Поэтому давайте создадим простейший проект на tornado.

Структура проекта элементарная:

```bash
└── project
    ├── app.py
    ├── home.html
    └── requirements.txt
```

app.py:

```python
import tornado.ioloop
import tornado.web

class HomeHandler(tornado.web.RequestHandler):
    def get(self):
        self.render("home.html", text="Hello, world!")

application = tornado.web.Application([
    tornado.web.url(r"/", HomeHandler, name='home'),
])

if __name__ == "__main__":
    application.listen(8888)
    tornado.ioloop.IOLoop.instance().start()
```

home.html:

{% raw %}
```html
<html>
   <head><title>Home page</title></head>
   <body>
     <div>Home page</div>
     <div>{{text}}</div>
   </body>
 </html>
```
{% endraw %}

requirements.txt:

```bash
tornado==4.0.2
```

#### Цель

Добавить в проект поддержку двух языков: английского и русского. Если у пользователя в браузере предпочитаемый язык английский - показывать текст на английском, если русский - то соответственно русский.

#### 1. Весь текст в коде должен быть на английском

У нас это уже выполнено, на данный момент в проекте есть такие строки:

```bash
"Hello, world!"  # app.py
"Home page"    # home.html
```

#### 2. Маркируем текст

Первым делом нужно обозначить строки, требующие перевода (пункт 2. раздела [gettext](#gettext)).    
Как мы помним, это делается функцией `_`.     
В коде обработчика ее можно получить так:

```python
_ = self.locale.translate
```

Код хендлера (файл app.py):

```python
class HomeHandler(tornado.web.RequestHandler):
    def get(self):
        _ = self.locale.translate
        self.render("home.html", text=_("Hello, world!"))
```

В шаблоне эта функция уже доступна, она определена в методе [get_template_namespace()](https://github.com/tornadoweb/tornado/blob/branch4.0/tornado/web.py#L788).    
Код шаблона (файл home.html):

{% raw %}
```html
<html>
   <head><title>{{_("Home page")}}</title></head>
   <body>
     <div>{{_("Home page")}}</div>
     <div>{{text}}</div>
   </body>
 </html>
}
```
{% endraw %}

Шаблонизатор tornado выполняет python код, который заключен внутри двойных фигурных скобок {% raw %}`{{ ... }}`{% endraw %}.

#### 3. Создаем файл перевода

Сперва создадим папку locale в корне нашего проекта:

```bash
mkdir locale
```

Далее создаем файлик `makemessages.sh` в корне проекта и кладем туда такой bash код:

```bash
#!/bin/bash 
# get arguments and init variables
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <locale> [optional: <domain_name>]"
    exit 1
fi
locale=$1
domain="messages"
if [ ! -z "$2" ]; then
    domain=$2
fi
locale_dir="locale/${locale}/LC_MESSAGES"
pot_file="locale/${domain}.pot"
po_file="${locale_dir}/${domain}.po"
# create folders if not exists
mkdir -p $locale_dir
# create .pot file
find . -iname "*.html" -o -iname "*.py" | xargs \
    xgettext --output=${pot_file} --language=Python --from-code=UTF-8 \
    --sort-by-file --keyword=_ --keyword=_:1,2 --no-wrap
# init .po file, if it doesn't exist yet
if [ ! -f $po_file ]; then
    msginit --input=${pot_file} --output-file=${po_file} --no-wrap --locale=${locale}
else
    # update .po file
    msgmerge --no-wrap --sort-by-file --output-file=${po_file} ${po_file} ${pot_file}
fi
```

Даем права на запуск:

```bash
chmod a+x makemessages.sh
```

При запуске нужно указать языковой тег. Для этого языка мы будем делать перевод, в данном примере это русский:

```bash
./makemessages.sh ru
```

При первом запуске может потребоваться ввести ваш email.   
После выполнения появятся файлы _messages.pot_ и _messages.po_:

```bash
project
├── locale
│   ├── ru
│   │   └── LC_MESSAGES
│   │       └── messages.po
│   └── messages.pot
├── app.py
├── home.html
├── requirements.txt
└── makemessages.sh
```

Содержимое messages.po:

```bash
# Russian translations for tornado_i18n package.
# Copyright (C) 2015 THE tornado_i18n'S COPYRIGHT HOLDER
# This file is distributed under the same license as the tornado_i18n package.
# stalk <alexevseev@gmail.com>, 2015.
#
msgid ""
msgstr ""
"Project-Id-Version: tornado_i18n\n"
"Report-Msgid-Bugs-To: \n"
"POT-Creation-Date: 2015-01-30 12:27+0300\n"
"PO-Revision-Date: 2015-01-30 12:27+0300\n"
"Last-Translator: stalk <alexevseev@gmail.com>\n"
"Language-Team: Russian\n"
"Language: ru\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=ASCII\n"
"Content-Transfer-Encoding: 8bit\n"
"Plural-Forms: nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2);\n"

#: app.py:8
msgid "Hello, world!"
msgstr ""

#: home.html:2 home.html:4
msgid "Home page"
msgstr ""
```

Здесь нужно **обязательно** поменять charset=ASCII на charset=UTF-8, остальные заголовки - опционально:

```
"Content-Type: text/plain; charset=UTF-8\n"
```

#### 4. Переводим

Заполняем пустые строки вида msgstr "" в _messages.po_ (не _.pot_!):

```bash
#: app.py:8
msgid "Hello, world!"
msgstr "Привет, мир!"

#: home.html:2 home.html:4
msgid "Home page"
msgstr "Домашняя страница"
```

#### 5. Компилируем перевод

Создаем файлик `compilemessages.sh` с кодом:

```bash
#!/bin/bash 
# get arguments and init variables
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <locale> [optional: <domain_name>]"
    exit 1
fi
locale=$1
domain="messages"
if [ ! -z "$2" ]; then
    domain=$2
fi
locale_dir="locale/${locale}/LC_MESSAGES"
po_file="${locale_dir}/${domain}.po"
mo_file="${locale_dir}/${domain}.mo"
# create .mo file from .po
msgfmt ${po_file} --output-file=${mo_file}
```

Даем права на запуск:

```bash
chmod a+x compilemessages.sh
```

При запуске указываем тот же языковой тег, что и для _makemessages.sh_:

```bash
./compilemessages.sh ru
```

Получился файл _locale/ru/LC_MESSAGES/messages.mo_:

```bash
project
├── locale
│   ├── ru
│   │   └── LC_MESSAGES
│   │       ├── messages.po
│   │       └── messages.mo
│   └── messages.pot
├── app.py
├── home.html
├── requirements.txt
├── compilemessages.sh
└── makemessages.sh
```

#### 6. Связываем перевод с нашим проектом

Для этого вызываем функцию [load_gettext_translations()](http://www.tornadoweb.org/en/stable/locale.html#tornado.locale.load_gettext_translations).

app.py:

```python
if __name__ == "__main__":
    tornado.locale.load_gettext_translations('locale', 'messages')
    application.listen(8888)
    tornado.ioloop.IOLoop.instance().start()
```

Попробуем запустить проект.    

```bash
python app.py
```

Откроем в browser_en адрес [http://127.0.0.1:8888/](http://127.0.0.1:8888/):

```
Home page
Hello, world!
```

и brower_ru:

```
Домашняя страница
Привет, мир!
```


Вот и все, перевод готов!

#### 7. Обновление перевода

Допустим, в файле home.html у нас добавился текст, который нужно перевести:

{% raw %}
```html
<div>{{_("Good buy!")}}</div>
}
```
{% endraw %}

В этом случае мы просто выполняем наш скрипт:

```bash
./makemessages.sh ru
```

заполняем перевод в обновленном _messages.po_:

```bash
#: home.html:6
msgid "Good buy!"
msgstr "До свидания!"
```

компилируем:

```bash
./compilemessages.sh ru
```

и перезапускаем сервер

```bash
python app.py
```

Все!


#### 8. Множественные значения

gettext поддерживает множественные значения (plural forms). Вот как это выглядит:

```bash
ngettext("{count} event is gonna happen", "{count} events are gonna happen", count).format(count=count)
```

ngettext - стандартное имя функции для множественных форм, которое используется в gettext.    
Но в tornado функция `self.locale.translate`, которую мы назвали как `_`, так же поддерживает аргументы ngettext. Вообщем, мы можем вместо ngettext использовать привычный нам `_`:

```python
_("{count} event is gonna happen", "{count} events are gonna happen", count).format(count=count)
```

Обратите внимание на аргументы функции xgettext в нашем скрипте выше:

```bash
--keyword=_ --keyword=_:1,2
```

Так мы указываем для парсера, что функция `_` может принимать как одну строку, так и две вместе с числом.

Смысл этого в том, что в зависимости от значения `count` строка будет принимать либо множественное значение, либо единичное.    
В случае английского языка это будет выглядеть так:

```python
_("{count} event is gonna happen", "{count} events are gonna happen", 1).format(count=1)
# вывод
"1 event is gonna happen"

_("{count} event is gonna happen", "{count} events are gonna happen", 2).format(count=2)
# вывод
"2 events are gonna happen"
```

Как мы видим, у английского языка только 1 форма множественного числа. Т.е. всегда, когда `count > 1`, вывод будет один и тот же.

Однако в русском языке может быть 3 формы (а в некоторых других языках и того больше). Давайте попробуем перевести вручную эту строку:

```
1,21,31 событие должно случиться
2,3,4,22 события должно случиться
5,6,7,8,9,20,25 событий должно случиться
```

Если мы все сделаем правильно, gettext будет выводить верную форму.

Реализуем это в нашем примере.    
Добавим в шаблон home.html такую строку:

{% raw %}
```html
<div>{{_("{count} event is gonna happen", "{count} events are gonna happen", count).format(count=count)}}</div>
```
{% endraw %}

а в обработчик из файла app.py:

```python
class HomeHandler(tornado.web.RequestHandler):
    def get(self):
        _ = self.locale.translate
        count = int(self.get_argument('count', 1))
        self.render("home.html", text=_("Hello, world!"), count=count)
```

Обновим наш файл переводов:

```bash
./makemessages.sh ru
```

Видим такие строки в _locale/ru/LC_MESSAGES/messages.po_:

```bash
#: home.html:6
#, python-brace-format
msgid "{count} event is gonna happen"
msgid_plural "{count} events are gonna happen"
msgstr[0] ""
msgstr[1] ""
msgstr[2] ""
```

gettext сам знает, что в русском языке для множественного значения может быть 3 формы.
Обратите внимание на заголовок, который был создан командой msginit:

```bash
"Plural-Forms: nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2);\n"
```

Условия из этого заголовка и определяют нужный вариант в зависимости от числа.    
Итак, добавим перевод:

```bash
#: home.html:6
#, python-brace-format
msgid "{count} event is gonna happen"
msgid_plural "{count} events are gonna happen"
msgstr[0] "{count} событие должно случиться"
msgstr[1] "{count} события должно случиться"
msgstr[2] "{count} событий должно случиться"
```

Скомпилируем:

```bash
./compilemessages.sh ru
```

Запустим сервер и попробуем обратиться из browser_ru

[http://127.0.0.1:8888/](http://127.0.0.1:8888/):

```
1 событие должно случиться
```

[http://127.0.0.1:8888/?count=2](http://127.0.0.1:8888/?count=2)

```
2 события должно случиться
```

[http://127.0.0.1:8888/?count=5](http://127.0.0.1:8888/?count=5)

```
5 событий должно случиться
```

Отлично!

#### 9. Особая логика для выбора языка

До сих пор язык пользователя определялся из настроек его браузера. Но допустим мы хотим, чтобы пользователь мог сам выбрать язык и сохранить его где-нибудь у себя в профиле на нашем сайте.    
Логику выбора языка можно легко изменить. Если мы это сделаем, то настройки браузера уже не будут влиять.    
Для этого просто нужно определить язык в методе `get_user_locale()`:

```python
class HomeHandler(tornado.web.RequestHandler):

    def get_user_locale(self):
        return tornado.locale.get("ru")

    def get(self):
        _ = self.locale.translate
        self.render("home.html", text=_("Hello, world!"))
```

Теперь независимо от браузера, текст всегда будет отображаться на русском языке.

Библиотека babel
---------------

Идем дальше. [babel](http://babel.pocoo.org/) предоставляет доступ к CLDR данным из python'а. Так же она реализует команды xgettext на python'e, т.о. xgettext можно не устанавливать. Но остановимся пока на CLDR.

Давайте попробуем вывести цену какого-нибудь продукта в долларах. В разных странах приняты разные способы отображения цен.    
Например, в России обычно указывают цену так: 99,00 $    
а в США так: $99.00    
а в какой-то другой стране еще по другому.

И эта информация, помимо всего прочего, есть в CLDR (рубли там тоже есть :))! Мы можем легко использовать ее благодаря babel.    
Установим babel:

```bash
pip install babel
```

Изменим app.py:

```python
import tornado.ioloop
import tornado.web
from babel.numbers import format_currency


class HomeHandler(tornado.web.RequestHandler):
    def get(self):
        _ = self.locale.translate
        count = int(self.get_argument('count', 1))
        format_usd = lambda p: format_currency(p, currency="USD",
            locale=self.locale.code)
        self.render("home.html", text=_("Hello, world!"), count=count,
            format_usd=format_usd)
```

а в шаблон home.html добавим цену:

{% raw %}
```html
<div>{{format_usd(99)}}</div>
```
{% endraw %}

И все, ничего больше делать не надо.    
browser_ru отобразит:

```
99,00 $
```

browser_en:

```
$99.00
```

Это лишь одна из множества функций, доступная в babel. Там есть дни недели, месяцев, форматы даты и многое другое. И этим можно и нужно пользоваться, не стоит переводить все вручную.

Реализация i18n в tornado с помощью babel <a name="tornado-i18n-babel"></a>
-----------------------------------------

Как я уже говорил, в babel реализованы основные функции xgettext на python'e. Т.о. можно не устанавливать xgettext. Так же в babel есть возможность задавать свой синтаксис для парсинга. Это может быть удобно для шаблонов html, где синтаксис отличается от python.

Возьмем все тот же наш маленький проект. По идее, нам нужно будет лишь изменить скрипты _makemessages.sh_ и _compilemessages.sh_.

Для чистоты эксперимента удалим все файлы внутри папки locale. Т.о. структура проекта будет такая:

```bash
project
├── locale
├── app.py
├── home.html
├── requirements.txt
├── makemessages.sh
└── compilemessages.sh
```

Установим babel, если еще не установили:

```bash
pip install babel
```

Так же для парсинга шаблонов tornado нам понадобится пакет [tornado-babel](https://pypi.python.org/pypi/Tornado-Babel/):

```bash
pip install tornado-babel
```

Первым делом нужно создать файл _locale/babel.cfg_ с содержимым:

```bash
[python: **.py]
[tornado: **.html]
```

Так мы указываем, какие файлы парсить и какой синтаксис использовать при парсинге.

Перепишем наш _makemessages.sh_, чтобы он вызывал команды babel вместо xgettext:

```bash
#!/bin/bash 
# get arguments and init variables
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <locale> [optional: <domain_name>]"
    exit 1
fi
locale=$1
domain="messages"
if [ ! -z "$2" ]; then
    domain=$2
fi
base_dir="locale"
locale_dir="${base_dir}/${locale}/LC_MESSAGES"
pot_file="${base_dir}/${domain}.pot"
po_file="${locale_dir}/${domain}.po"
babel_config="${base_dir}/babel.cfg"
# create pot template
pybabel extract ./ --output=${pot_file} \
    --charset=UTF-8 --no-wrap --sort-by-file \
    --keyword=_ --mapping=${babel_config}
# init .po file, if it doesn't exist yet
if [ ! -f $po_file ]; then
    pybabel init --input-file=${pot_file} --output-dir=${base_dir} \
        --domain=${domain} --locale=${locale} --no-wrap
else
    # update .po file
    pybabel update --domain=${domain} --input-file=${pot_file} \
    --output-dir=${base_dir} --locale=${locale} --no-wrap
fi
```

А так же compilemessages.sh:

```bash
#!/bin/bash 
# get arguments and init variables
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <locale> [optional: <domain_name>]"
    exit 1
fi
locale=$1
domain="messages"
if [ ! -z "$2" ]; then
    domain=$2
fi
locale_dir="locale/${locale}/LC_MESSAGES"
po_file="${locale_dir}/${domain}.po"
mo_file="${locale_dir}/${domain}.mo"
# create .mo file from .po
pybabel compile --locale=${locale} --domain=${domain} --directory=locale/
```

Если вы заметили, мы указываем только `--keyword=_`. Без `--keyword=_:1,2`. Почему?    
Дело в том, что в версии babel==1.3, которая доступна из pypi на момент написания статьи, не поддерживаются разные аргументы для одной и той же функции.    
На что это влияет в нашем случае?    
Нам придется для множественных форм использовать функцию `ngettext`, а не `_`.    
Для этого поправим чуть-чуть app.py, определив `ngettext` и передав ее в шаблон:

```python
class HomeHandler(tornado.web.RequestHandler):

    def get(self):
        ngettext = _ = self.locale.translate
        # ...
        self.render("home.html", text=_("Hello, world!"), count=count,
            ngettext=ngettext)
```

и в шаблоне для перевода множественных форм используем ngettext:

{% raw %}
```html
 <div>{{ngettext("{count} event is gonna happen", "{count} events are gonna happen", count).format(count=count)}}</div>
```
{% endraw %}

Дальше все по старому.

Создаем файлы перевода:

```bash
./makemessages.sh ru
```

Опять добавляем перевод в _locale/ru/LC_MESSAGES/messages.po_.

Компилируем:

```bash
./compilemessages.sh ru
```

При выполнении этого скрипта можно увидеть что-то вроде

```bash
catalog 'locale/ru/LC_MESSAGES/messages.po' is marked as fuzzy, skipping
```

Тогда нужно в файле _messages.po_ удалить такие строки, говорящие, что перевод не подтвержденный:

```bash
#, fuzzy
```

и опять скомпилировать перевод.

И теперь все работает аналогично. Но без xgettext!

#### Исправляем babel

Согласитесь, что неудобно иметь две функции `_` и `ngettext`. Давайте это исправим! :)    
Я отправил pull-request'ы в [babel репозиторий](https://github.com/mitsuhiko/babel/pull/140) и в [tornado-babel](https://github.com/openlabs/tornado-babel/pull/6). Возможно, они уже приняты.    
Однако, чтобы не ждать, есть готовые версии с этими исправлениями. Но вначале удалим текущие babel и tornado-babel:

```bash
pip uninstall babel
pip uninstall tornado-babel
```

Ставим исправленные версии:

```bash
pip install https://github.com/st4lk/babel/archive/2.1.2-draft.tar.gz
pip install https://github.com/st4lk/tornado-babel/archive/0.3b.tar.gz
```

Добавим `--keyword=_1,2` в _makemessages.sh_.    
Было:

```bash
--keyword=_ --mapping=${babel_config}
```

Стало:

```bash
--keyword=_ --keyword=_:1,2 --mapping=${babel_config}
```

Уберем теперь уже не нужную функцию ngettext.

app.py:

```python
class HomeHandler(tornado.web.RequestHandler):

    def get(self):
        _ = self.locale.translate
        # ...
        self.render("home.html", text=_("Hello, world!"), count=count)
```

home.html:

{% raw %}
```html
<div>{{_("{count} event is gonna happen", "{count} events are gonna happen", count).format(count=count)}}</div>
```
{% endraw %}

Ура, теперь мы работаем с babel точно так же, как и с xgettext!

Если что, код примера на github'e: [https://github.com/st4lk/tornado_i18n_example](https://github.com/st4lk/tornado_i18n_example)
