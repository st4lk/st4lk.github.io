---
layout: post
title:  "Tornado i18n and l10n"
date:   2015-01-31 18:19:43 +0000
categories: i18n async tornado
redirect_from:
  - /2015/tornado-internationalization-and-localization/
---

<a class="github-button" href="https://github.com/st4lk/tornado_i18n_example" data-color-scheme="no-preference: light; light: light; dark: dark;" data-size="large" data-show-count="true" aria-label="Star st4lk/tornado_i18n_example on GitHub">Star</a>

[![Tornado i18n and l10n](https://img-fotki.yandex.ru/get/4/85893628.c67/0_1715c7_738478c6_orig.png "Tornado i18n and l10n")]({{ site.baseurl }}{{ page.url }})

Let's talk about i18n, i10n and [tornado](http://www.tornadoweb.org/en/stable/) implementation. This post have a lot of text, but i wanted to describe many things that i faced during realization of i18n in tornado project. The step by step instruction is placed in the second part of this article.

<!--more-->

Common definitions
-----------------

#### i18n

i18n - shorthand from internationalization. It mean the process of multiple languages support in application. It is not the translation itself, but technical part of the project, that allows to show text in different languages depending on user preferences. Usually done by developer.

#### l10n

l10n - shorthand from localization. It mean the translation process. Usually done by translator.

#### Language tags

[Language tags](http://www.w3.org/International/articles/language-tags/) define the language. Tag format contains many nuances, all of them are described in [rfc5646](http://www.rfc-editor.org/rfc/rfc5646.txt).    
But the most common used format is following:

```
en-US
```

First part define language and second - region. In current example tag `en-US` means english language, that is used in USA. And for example `en-GB` will mean english language, that is used in Great Britain (i suppose they differs a little bit). In language tag only one subtag is mandatory - language. Therefore this is correct tag:

```
en
```

Moreover, if region subtag is not necessary - don't use it.

#### CLDR

[CLDR](http://cldr.unicode.org/) - Common Locale Data Repository.    
Contains commonly used data in different langauges:

- format of date, price in different currencies, timezones
- country names, week days, months
- rules of writing numbers, plural forms, write direction, first week day
- and etc.

gettext<a name="gettext"></a>
------
[gettext](https://www.gnu.org/software/gettext/) - library that realise i18n process. In this article working with this lib is described.

Torando allows also working with [CSV files](http://www.tornadoweb.org/en/stable/locale.html#tornado.locale.load_translations), but this approach have much less features, so i'll not describe it here.

#### Short description of gettext workflow
1. All text strings in code must be written in english.
2. Mark translatable strings.

    Put all strings as argument of special function, implemented in gettext. In python function with name `_` is usually used.
    Was:
    ```python
    "Hello world!"
    ```
    Now:
    ```python
    _("Hello world!")
    ```

3. Create `.pot` template file.

    It can be done with [xgettext](https://www.gnu.org/software/gettext/manual/html_node/xgettext-Invocation.html#xgettext-Invocation) util. It parse specified files, find calls of function `_` and generate file _messages.pot_.
    This file will contain strings to be translated, along with some preference headers:    
    ```bash
    msgid "Hello world!"
    msgstr ""
    ```
    This file shall not be modified by hand. Strictly speaking, we don't need it for translations, it just a helper. For example, django i18n scripts don't save it anywhere. But let us keep it, as this file will be useful to update our translations. Also, we can give this file for translator to show him work amount.

4. Create translation file in exact language.
  
    Command [msginit](https://www.gnu.org/software/gettext/manual/html_node/msginit-Invocation.html) can be used for this, it will take template _messages.pot_ as input and produce new file _messages.po_ as output. If fact, we'll get a copy of our template, but some parts will be set according to chosen language.

5. Translate strings in _messages.po_ manually:

    ```bash
    msgid "Hello world!"
    msgstr "Привет, мир!"
    ```

6. Compile translation by command [msgfmt](https://www.gnu.org/software/gettext/manual/html_node/msgfmt-Invocation.html). We'll get _messages.mo_ as output.

7. If new strings are added somewhere in our application, just update _messages.po_, don't create it from scratch.

    Thus previous translations will not be lost. To achieve it:    
    - again create template _.pot_ (point 3). Yes, it will replace previous _messages.pot_. But it's ok as we never modify it manually.
    - use command [msgmerge](https://www.gnu.org/software/gettext/manual/html_node/msgmerge-Invocation.html), it will synchronise _.po_ and _.pot_ files.
    - repeat points 5 and 6.

That's it. If function `_` in our project works properly, then englishman will see "Hello world!", whereas russian - "Привет, мир!".

It remains unclear, how function `_` is implemented and where we can get it. Also, how we discover user preferred language, who is he - englishman or russian? Where we can get those utilities `xgettext`, `msginit`, `msgmerge`, `msgfmt`?

Let's go step by step.

#### Function _

This function can be written manually, as python has builtin support of [gettext](https://docs.python.org/2/library/gettext.html). However, tornado and django already implemented it. We need just to assign name `_` to it.    
Django example:

```python
from django.utils.translation import ugettext as _
_("Hello world!")
```

And tornado:

```python
class SomeHandler(tornado.web.RequestHandler):
    def get(self):
        _ = self.locale.translate
        _("Hello world!")
```

#### How function `_` discover user preferred language?

In most simple case web application knows language from HTTP header Accept-Language (preferred language is set in browser settings). Django and tornado have it.    
For more complicated logic, when for example user can specify locale in his profile on web site, both frameworks have corresponding means for it.    
Unlike django, tornado can **not** determine language from url prefix out of the box. I mean that django can show russian content for url `/ru/.../` and english content for `/en/.../`. But tornado haven't this functionality, we must implement it manually.

#### Where to get utils `xgettext`, `msginit`, `msgmerge`, `msgfmt`

Install :).

Some Ubuntu versions already have them. If not, run this command:

```bash
sudo apt-get install gettext
```

OSX:

```bash
brew install gettext
brew link gettext --force
```

Windows binaries can be downloaded from here (haven't tried): [http://gnuwin32.sourceforge.net/packages/gettext.htm](http://gnuwin32.sourceforge.net/packages/gettext.htm)

If you are having trouble with install, then you can use builtin python scripts: [`pygettext.py`, `msgfmt.py`](https://docs.python.org/2/library/gettext.html#internationalizing-your-programs-and-modules). But they have much less features, than xgettext. For example, no _msgmerge_ script that is extremely useful.

One solution is also available - [babel](http://babel.pocoo.org/) package. It implements many xgettext utils in python, including msgmerge. So we don't need xgettext to be installed. I'll describe this approach later in this article.

Differences between tornado and django
----------------------------------

Before starting the step by step instruction of implementing i18n in tornado, i want to pay attention on one feature.    
It is extremely important for understanding how tornado is working.

The main differences between tornado and django is that tornado runs in single process whereas django - not. How it corresponds to text translation?    
In django we can mark strings as translatable anywhere in code, even in models. For such purpose django has 'lazy' function, for example [ugettext_lazy](https://docs.djangoproject.com/en/dev/topics/i18n/translation/#working-with-lazy-translation-objects):

```python
from django.db import models
from django.utils.translation import ugettext_lazy as _

class SomeModel(models.Model):
    title = models.CharField(_("Title"), max_length=50)
```

Function `ugettext_lazy` doesn't return string immediately, only at direct access, when locale will be discovered. But how it knows this locale?    
Obviously, client must make a request, so we can determine some information about visitor from this request and discover his localisation. After that django will store found language in thread global variable (using function [activate()](https://docs.djangoproject.com/en/dev/ref/utils/#django.utils.translation.activate)). Remember, that django process every request in separate process.    
That is why function `ugettext_lazy` can be used anywhere in code, it will translate text correctly. It doesn't need the request instance as all needed data will be taken from global variable.

In tornado such approach is not working because it always run in single thread. It is a feature of asynchronous applications.    
But what can happen, if we'll try to implement this "lazy" pattern?    
Let's try. Take a look at this simple tornado project. For "lazy" realisation we'll use [speaklater](https://pypi.python.org/pypi/speaklater) package:

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

Here `HiModel` and `DoneModel` represent some models. The most important part - they have translatable strings.    
Translation in _messages.po_ look like this:

```bash
msgid "Hello, world!"
msgstr "Привет, мир!"

msgid "Fuh, done"
msgstr "Фух, вроде готово"
```

Run this small server.    
Assume, that "browser_en" have english preferred language and "browser_ru" - russian.

Open url [http://127.0.0.1:8888/](http://127.0.0.1:8888/) in browser_ru and see:

```
Привет, мир!
Фух, вроде готово
```

Same action in browser_en:

```
Hello, world!
Fuh, done
```

All is working fine. But let's try to add async task. For simplicity we'll use [async timer](http://tornado.readthedocs.org/en/latest/ioloop.html#tornado.ioloop.IOLoop.add_timeout):

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

So we just added these lines:

```python
    io_loop = tornado.ioloop.IOLoop.instance()
    yield tornado.gen.Task(io_loop.add_timeout, timedelta(seconds=5))
```

between models `HiModel` and `DoneModel`.    
Now open url first from browser_ru, then from browser_en, but before timer in browser_ru will be done.

In browser_ru we'll see:

```
Привет, мир!
Fuh, done
```

and in browser_en:

```
Hello, world!
Fuh, done
```

I hope you already understand, why browser_ru show one string in russian and one in english. Just in case let's describe this situation in details.

When browser_ru made a request, we have set russian locale globally.    
Then async task was fired.    
While async task was working, browser_en made a request. Now we have set english locale globally.    
Async task, that was fired by browser_ru, was finished and handler continued to work. But language was modified from another request, so from this moment strings 
will be translated to english, not to russian.

Therefore we can make a decision, that in tornado we can correctly discover language **only** from request handler instance.

i18n in tornado using xgettext <a name="tornado-i18n-xgettext"></a>
--------------------------

In [tornado docs](http://www.tornadoweb.org/en/stable/locale.html#module-tornado.locale) realisation of i18n is described quite poorly, so i'll try to make a step by step instruction here.

To my mind, the best way to describe is to show on example. Therefore let's create simple tornado project.

Project structure:

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

```python
tornado==4.0.2
```

#### Goal

Add support of two languages, english and russian, in tornado project. If browser have english as preferred language - show english content and if russian - show russian content correspondingly.

#### 1. All text in code must be in english

We already have it, currently there are such strings:

```bash
"Hello, world!"  # app.py
"Home page"    # home.html
```

#### 2. Mark text

First of all we need to mark translatable strings (point 2 from [gettext](#gettext) section).    
As we remember, it is done by function `_`.
In request handler code we can get it like this:   

```python
_ = self.locale.translate
```

Handler code (file app.py):

```python
class HomeHandler(tornado.web.RequestHandler):
    def get(self):
        _ = self.locale.translate
        self.render("home.html", text=_("Hello, world!"))
```

In templates this function is available by default, it is defined in method [get_template_namespace()](https://github.com/tornadoweb/tornado/blob/branch4.0/tornado/web.py#L788).    
Template code (file home.html):

{% raw %}
```html
<html>
   <head><title>{{_("Home page")}}</title></head>
   <body>
     <div>{{_("Home page")}}</div>
     <div>{{text}}</div>
   </body>
 </html>
```
{% endraw %}

Tornado template system execute python code, that is placed inside double braces {% raw %}`{{ ... }}`{% endraw %}.

#### 3. Create file with translations

Create locale folder in the root of our project:

```bash
mkdir locale
```

Next create file `makemessages.sh` in root and put such bash code there:

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

Add execution rights:

```bash
chmod a+x makemessages.sh
```

To launch it is needed to specify language tag. This is the language that we want to implement (in this example - russian):

```bash
./makemessages.sh ru
```

During first launch it can ask you email.    
After execution files _messages.pot_ and _messages.po_ will be created:

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

Contents of messages.po:

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

We **must** change charset=ASCII to charset=UTF-8 here, other headers are optional:

```
"Content-Type: text/plain; charset=UTF-8\n"
```

#### 4. Do translation

Fill empty strings like msgstr "" in _messages.po_ (not _.pot_!):

```bash
#: app.py:8
msgid "Hello, world!"
msgstr "Привет, мир!"

#: home.html:2 home.html:4
msgid "Home page"
msgstr "Домашняя страница"
```

#### 5. Compile translation

Create file `compilemessages.sh` with bash code:

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

Add execution rights:

```bash
chmod a+x compilemessages.sh
```

To launch specify same language tag, as in _makemessages.sh_:

```bash
./compilemessages.sh ru
```

We've got file _locale/ru/LC_MESSAGES/messages.mo_:

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

#### 6. Link translations with our project

To achieve it call function [load_gettext_translations()](http://www.tornadoweb.org/en/stable/locale.html#tornado.locale.load_gettext_translations).

app.py:

```python
if __name__ == "__main__":
    tornado.locale.load_gettext_translations('locale', 'messages')
    application.listen(8888)
    tornado.ioloop.IOLoop.instance().start()
```

Let's try to start the project.

```bash
python app.py
```

Open address [http://127.0.0.1:8888/](http://127.0.0.1:8888/) in browser_en:

```bash
Home page
Hello, world!
```

and brower_ru:

```bash
Домашняя страница
Привет, мир!
```

That's it, translation is done!

#### 7. Update translation

Imagine, that in home.html we have new text, that must be translated:

{% raw %}
```html
<div>{{_("Good buy!")}}</div>
```
{% endraw %}

We just execute our script:

```bash
./makemessages.sh ru
```

fill translations in updated _messages.po_:

```bash
#: home.html:6
msgid "Good buy!"
msgstr "До свидания!"
```

compile:

```bash
./compilemessages.sh ru
```
and restart server

```bash
python app.py
```

That's all!

#### 8. Plural forms

gettext can handle plural forms, here is how it works:

```bash
ngettext("{count} event is gonna happen", "{count} events are gonna happen", count).format(count=count)
```

ngettext - standard function name for plural forms that is used in gettext.    
But tornado function `self.locale.translate` also accept plural forms arguments. So we can use our usual name `_` instead of ngettext:

```python
_("{count} event is gonna happen", "{count} events are gonna happen", count).format(count=count)
```

Pay attention on xgettext options in your script above:

```bash
--keyword=_ --keyword=_:1,2
```

With this options we tell the parser, that function `_` can accept both single string and plural form strings as arguments.

Plural forms function will return either single form, either plural form, depending on provided count.    
Example in english:

```python
_("{count} event is gonna happen", "{count} events are gonna happen", 1).format(count=1)
# output
"1 event is gonna happen"

_("{count} event is gonna happen", "{count} events are gonna happen", 2).format(count=2)
# output
"2 events are gonna happen"
```

As we can see, english language have only 1 plural form. I.e. when `count > 1` the output will be the same.

However russian language have 3 plural forms (and some other languages even more). Here is an example:

```
1,21,31 событие должно случиться
2,3,4,22 события должно случиться
5,6,7,8,9,20,25 событий должно случиться
```

If we'll do everything correctly, gettext will produce the right form.

Let's implement it in our example.    
Add following line in home.html:

{% raw %}
```html
<div>{{_("{count} event is gonna happen", "{count} events are gonna happen", count).format(count=count)}}</div>
```
{% endraw %}

in handler from app.py:

```python
class HomeHandler(tornado.web.RequestHandler):
    def get(self):
        _ = self.locale.translate
        count = int(self.get_argument('count', 1))
        self.render("home.html", text=_("Hello, world!"), count=count)
```

Update translations:

```bash
./makemessages.sh ru
```

Now we can find such strings in _locale/ru/LC_MESSAGES/messages.po_:

```bash
#: home.html:6
#, python-brace-format
msgid "{count} event is gonna happen"
msgid_plural "{count} events are gonna happen"
msgstr[0] ""
msgstr[1] ""
msgstr[2] ""
```

gettext knows, that russian langauge has 3 plural forms.    
Look at header, that was created by msginit:

```bash
"Plural-Forms: nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2);\n"
```

Conditions from this header define correct plural form depending on provided count.    
Do the translation:

```bash
#: home.html:6
#, python-brace-format
msgid "{count} event is gonna happen"
msgid_plural "{count} events are gonna happen"
msgstr[0] "{count} событие должно случиться"
msgstr[1] "{count} события должно случиться"
msgstr[2] "{count} событий должно случиться"
```

Compile:

```bash
./compilemessages.sh ru
```

Start the server and open in browser_ru

[http://127.0.0.1:8888/](http://127.0.0.1:8888/):

```bash
1 событие должно случиться
```

[http://127.0.0.1:8888/?count=2](http://127.0.0.1:8888/?count=2)

```bash
2 события должно случиться
```

[http://127.0.0.1:8888/?count=5](http://127.0.0.1:8888/?count=5)

```bash
5 событий должно случиться
```

Great!

#### 9. Custom logic for discovering language

Language was determined from browser settings so far. But what if we want to let the user to choose his preferred locale in our web project, for example in his profile.    
This logic can be easily customised and browser settings will not be the mandatory setting.    
Just override handler's method `get_user_locale()`:

```python
class HomeHandler(tornado.web.RequestHandler):

def get_user_locale(self):
    return tornado.locale.get("ru")

def get(self):
    _ = self.locale.translate
    self.render("home.html", text=_("Hello, world!"))
```

Now regardless of browser settings the russian content will always be shown.

babel package
------------

Go further. [babel](http://babel.pocoo.org/) provides access to CLDR data from python. Also it implement xgettext commands in pure python, thus we don't need xgettext installed. But now let's look at CLDR more carefully.

Suppose we want to show some product price is US dollars. But in different countries different currency format is used.    
For example in Russia price is often written as: 99,00 $    
whereas in USA: $99.00

All this information is available in CLDR! We can easily use it thanks to babel.    
Install babel:

```bash
pip install babel
```

Modify app.py:

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

add price in home.html:

{% raw %}
```html
<div>{{format_usd(99)}}</div>
```
{% endraw %}

That's all we need to do.    
browser_ru will show:

```
99,00 $
```

browser_en:

```
$99.00
```

This is only one of many features available in babel. It have translations of week days, months, date formats and many other. And we shall use it, no need to translate everything by hand.

i18n in tornado using babel <a name="tornado-i18n-babel"></a>
-----------------------------------------

As I said before, babel implement main xgettext commands in python. So we don't need xgettext installed. Also, babel allows to declare custom syntax for parsing. It is useful when we have templates with some specific syntax in it.

Take again our simple example. In theory we just need to change our scripts _makemessages.sh_ and _compilemessages.sh_.


For the purity of the experiment delete all files inside locale folder. Project structure now looks like this:

```bash
project
├── locale
├── app.py
├── home.html
├── requirements.txt
├── makemessages.sh
└── compilemessages.sh
```

Install babel, if not already:

```bash
pip install babel
```

For tornado templates parsing we'll need package [tornado-babel](https://pypi.python.org/pypi/Tornado-Babel/):

```bash
pip install tornado-babel
```

First of all create file _locale/babel.cfg_ with following code:

```bash
[python: **.py]
[tornado: **.html]
```

By this code we tell babel, what files must be used for parsing (as you remember, for xgettext we used `find . -iname "*.html" -o -iname "*.py"`).

Modify our _makemessages.sh_, so babel will be used instead of xgettext:

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

And compilemessages.sh:

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

Maybe you have noticed, that we use only `--keyword=_` option, without `--keyword=_:1,2`. Why?    
The thing is that in babel==1.3, that is currently avaliable from pypi, multiple arguments for same function are not supported.    
What impact it have in our case?    
We have to use `ngettext` function name for plural forms instead of `_`.    
Modify code in app.py a little:

```python
class HomeHandler(tornado.web.RequestHandler):

    def get(self):
        ngettext = _ = self.locale.translate
        # ...
        self.render("home.html", text=_("Hello, world!"), count=count,
            ngettext=ngettext)
```

and template:

{% raw %}
```html
 <div>{{ngettext("{count} event is gonna happen", "{count} events are gonna happen", count).format(count=count)}}</div>
```
{% endraw %}

Other code remains the same.

Create translation files:

```bash
./makemessages.sh ru
```

Again do translation in _locale/ru/LC_MESSAGES/messages.po_.

Compile:

```bash
./compilemessages.sh ru
```

During execution of this script we can see something like

```bash
catalog 'locale/ru/LC_MESSAGES/messages.po' is marked as fuzzy, skipping
```

In that case delete special untrusted translation marks in _messages.po_:
```bash
#, fuzzy
```
and compile again.

Now all works similarly. But without xgettext!

#### Fix babel

Agree, that uncomfortable to have two functions `_` and `ngettext`. Let's fix it! :)    
I've send pull-requests into [babel repo](https://github.com/mitsuhiko/babel/pull/140) and in [tornado-babel repo](https://github.com/openlabs/tornado-babel/pull/6). Maybe they are already accepted.    
However i've created fixed versions to not wait for acceptance. Uninstall current babel and tornado-babel packages:

```bash
pip uninstall babel
pip uninstall tornado-babel
```

Install fixed versions:

```bash
pip install https://github.com/st4lk/babel/archive/2.1.2-draft.tar.gz
pip install https://github.com/st4lk/tornado-babel/archive/0.3b.tar.gz
```

Add `--keyword=_1,2` option in _makemessages.sh_.    

Was:

```bash
--keyword=_ --mapping=${babel_config}
```
Now:

```bash
--keyword=_ --keyword=_:1,2 --mapping=${babel_config}
```

Remove unnecessary ngettext function.

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

Great, now we use babel and code is the same, as with xgettext!

The code of example is available on github: [https://github.com/st4lk/tornado_i18n_example](https://github.com/st4lk/tornado_i18n_example)
