---
layout: post
title:  "Многоязычный сайт на django без редиректов"
date:   2013-02-26 18:19:43 +0000
categories: django i18n
redirect_from:
  - /2013/multilanguage-site-django-without-redirects/
---

<a class="github-button" href="https://github.com/st4lk/django-solid-i18n-urls" data-color-scheme="no-preference: light; light: light; dark: dark;" data-size="large" data-show-count="true" aria-label="Star st4lk/django-solid-i18n-urls on GitHub">Star</a>

Начиная с django 1.4, можно задать [префикс для url](https://docs.djangoproject.com/en/dev/topics/i18n/translation/#language-prefix-in-url-patterns) для каждого включенного языка. К примеру, мы хотим сайт, который будет иметь русскую и английскую версию.

Для этого добавляем в `settings.py`:

<!--more-->

```python
# default language, it will be used, if django can't recognize user's language
LANGUAGE_CODE = 'ru'

# list of activated languages
LANGUAGES = (
    ('ru', 'Russian'),
    ('en', 'English'),
)

# enable django’s translation system
USE_I18N = True

# specify path for translation files
LOCALE_PATHS = (
    os.path.join(PROJECT_DIR, 'locale'),
)

# add LocaleMiddleware
MIDDLEWARE_CLASSES = (
   # ...
   'django.middleware.locale.LocaleMiddleware',
   # ...
)
```

И в `urls.py` используем i18n_patterns вместо patterns:

```python
from django.conf.urls import url
from django.conf.urls.i18n import i18n_patterns

urlpatterns = i18n_patterns('',
    url(r'^about/$', 'about.view', name='about'),
)
```

В этом случае, когда мы обратимся по адресу /about/, django [попытается определить](https://docs.djangoproject.com/en/dev/topics/i18n/translation/#how-django-discovers-language-preference) предпочитаемый нами язык и сделает редирект на страницу с префиксом языка. Допустим django определил, что наш язык - русский, тогда произойдет редирект на /ru/about/. При этом, если мы сами пройдем по адресу /en/about/, то уже никаких редиректов не будет, а отобразится английская версия сайта, т.к. в url уже присутствует префикс /en/.

При такой схеме могут возникнуть проблемы с индексированием сайта некоторыми поисковыми системами. Например [yandex.ru](http://yandex.ru/) очень долго отказывался индексировать сайт, т.к. не получал http кода 200 с корневого url. C Google'ом таких проблем не было, но все же и он не рекомендует использовать редиректы. Из [http://support.google.com/webmasters/bin/answer.py?hl=ru&answer=182192](http://support.google.com/webmasters/bin/answer.py?hl=ru&answer=182192):

> Избегайте автоматического перенаправления по языку пользователя. Это может привести к тому, что пользователи и поисковые системы не смогут просмотреть все версии вашего сайта.

**Поэтому я решил создать пакет, который позволял бы работать без редиректов**.

Схема работы будет такая:

1. Если в url нет языкового префикса, то используется язык по умолчанию (`settings.LANGUAGE_CODE`)
2. Если префикс есть, то используется язык, соответствующий префиксу (/en/ = англ), но при этом префикса для языка по умолчанию нет.

Благо для этого нужно совсем немного кода, нужно лишь изменить LocaleMiddleware и i18n_patterns, что я и сделал в репозитории [https://github.com/st4lk/django-solid-i18n-urls](https://github.com/st4lk/django-solid-i18n-urls).

Установка:

1. Устанавливаем django-solid-i18n-urls, например с помощью pip:

    ```bash
    pip install solid_i18n
    ```

2. Изменяем LocaleMiddleware на SolidLocaleMiddleware:

    ```python
    MIDDLEWARE_CLASSES = (
       # ...
       # remove 'django.middleware.locale.LocaleMiddleware',
       'solid_i18n.middleware.SolidLocaleMiddleware', 
       # ...
    )
    ```

3. Вместо i18n_patterns используем solid_i18n_patterns:

    ```python
    from django.conf.urls import url
    from solid_i18n.urls import solid_i18n_patterns
  
    urlpatterns = solid_i18n_patterns('',
        url(r'^about/$', 'about.view', name='about'),
    )
    ```

Репозиторий на github: [https://github.com/st4lk/django-solid-i18n-urls](https://github.com/st4lk/django-solid-i18n-urls).


### UPDATED

Добавлена опция `settings.SOLID_I18N_USE_REDIRECTS` (по умолчанию False). Если она равна True, то будут использованы редиректы по следующим правилам:

1. При обращении по url без языкового префикса, например `'/'`, язык будет определен из [предпочтений](https://docs.djangoproject.com/en/dev/topics/i18n/translation/#how-django-discovers-language-preference) пользователя. Если этот язык не равен языку по умолчанию (`settings.LANGUAGE_CODE`), то будет перенаправление на url с соответствующем префиксом. Если равен, то отображается url без префикса (который и был запрошен).
2. При обращении по url с языковым префиксом поведение не меняется, т.е. всегда используется язык из префикса.



Привет:
```python
# settings.py: 
LANGUAGE_CODE = 'ru'
SOLID_I18N_USE_REDIRECTS = True
```
Допустим предпочитаемый язык пользователя - английский.

Тогда при обращении к `'/'` будет редирект на `'/en/'`.

А если предпочитаемый язык - русский, то редиректа не будет, т.е. при обращении к `'/'` оторбразиться `'/'`.

#### Замечание
При таком подходе возможна следующая ситуация. Предпочитаемый язык браузера - английский. Но пользователь хочет увидеть русскую версию, которая отображается без префикса. Если для переключения языков использовать простые ссылки, т.е. {% raw %}`<a href="{{ specific language url}}">`{% endraw %}, то пользователь будет постоянно перенаправляться на английскую версию. Поэтому при переключении языков надо записывать в cookie пользователя выбранный им язык. Это можно делать с помощью специального встроенного в django [set_language](https://docs.djangoproject.com/en/dev/topics/i18n/translation/#the-set-language-redirect-view) view.
