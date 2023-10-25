---
layout: post
title:  "Multilanguage site on django without redirects"
date:   "2013-02-26 18:19:43 +0000"
categories: django i18n
redirect_from:
  - /2013/multilanguage-site-django-without-redirects/
  - /blog/2013/02/26/multilanguage-site-django-without-redirects.html
---

<a class="github-button" href="https://github.com/st4lk/django-solid-i18n-urls" data-color-scheme="no-preference: light; light: light; dark: dark;" data-size="large" data-show-count="true" aria-label="Star st4lk/django-solid-i18n-urls on GitHub">Star</a>

Starting from django 1.4, it is possible to set [url prefix](https://docs.djangoproject.com/en/dev/topics/i18n/translation/#language-prefix-in-url-patterns) for each activated language. For example, we want site, that will have russian and english version.

To do it, add following to `settings.py`:

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

And in `urls.py` use i18n_patterns instead of patterns:

```python
from django.conf.urls import url
from django.conf.urls.i18n import i18n_patterns

urlpatterns = i18n_patterns('',
    url(r'^about/$', 'about.view', name='about'),
)
```

In this case on access to /about/, django will [try to discover](https://docs.djangoproject.com/en/dev/topics/i18n/translation/#how-django-discovers-language-preference) language preference and make redirect to url with corresponding language prefix. Let's say, that django has discovered russian language, then browser will be redirected to /ru/about/. But, if we'll type url /en/about/, no redirects will occur and english version will be shown, because url already has prefix /en/.

But with such pattern can be problems with site indexing by some search engines. For example yandex.ru refused to index my site for a long time, because it doesn't fetched http code 200 from site root. With google there were no such problems, but anyway, in help page it is not recommended to use redirects. From [http://support.google.com/webmasters/bin/answer.py?hl=en&answer=182192](http://support.google.com/webmasters/bin/answer.py?hl=en&answer=182192):

> Avoid automatic redirection based on the user’s perceived language. These redirections could prevent users (and search engines) from viewing all the versions of your site.

**So i decided to make tool, that will work without redirects**.

The algorithm is following:

1. If url doesn't have language prefix, then default language will be used (`settings.LANGUAGE_CODE`)
2. If url has prefix, then language will be determined from this prefix (/en/ = english), but for default language there is no prefix.

Luckily, it is needed a little peace of code for this, we need just to change LocaleMiddleware and i18n_patterns. I've made it in repo [https://github.com/st4lk/django-solid-i18n-urls](https://github.com/st4lk/django-solid-i18n-urls).

Installation:

1. Setup django-solid-i18n-urls, for example using pip:

    ```bash
    pip install solid_i18n
    ```

2. Change LocaleMiddleware to SolidLocaleMiddleware:

    ```python
    MIDDLEWARE_CLASSES = (
       # ...
       # remove 'django.middleware.locale.LocaleMiddleware',
       'solid_i18n.middleware.SolidLocaleMiddleware', 
       # ...
    )
    ```

3. Use solid_i18n_patterns instead of i18n_patterns:

    ```python
    from django.conf.urls import url
    from solid_i18n.urls import solid_i18n_patterns
  
    urlpatterns = solid_i18n_patterns('',
        url(r'^about/$', 'about.view', name='about'),
    )
    ```

Repo on github: [https://github.com/st4lk/django-solid-i18n-urls](https://github.com/st4lk/django-solid-i18n-urls).


### UPDATED

Option `settings.SOLID_I18N_USE_REDIRECTS` is added (False by default). If it is True, then redirects will be used with following rules:

1. On request to url without language prefix, for example `'/'`, language will be determied from [user preferences](https://docs.djangoproject.com/en/dev/topics/i18n/translation/#how-django-discovers-language-preference). If that language is not equal to default (`settings.LANGUAGE_CODE`), then he will be redirected to corresponding url with prefix. But if it is equal, then url without prefix will be shown.
2. On request to url with language prefix behaviour remains the same, i.e. language from prefix is used.

Example:
```python
# settings.py: 
LANGUAGE_CODE = 'ru'
SOLID_I18N_USE_REDIRECTS = True
```
Suppose preferred user language is english.

Then at request to `'/'` will be redirect to `'/en/'`.

And if preferred language is russian, then no redirect will occur, i.e. on request to '/' exactly that url will be rendered.

#### Note
In such approach there is some nasty case. Imagine, that preferred browser language - english. But user wants to see russian version, that is rendered at url without prefix. If for switching language simple links are used like {% raw %}`<a href="{{ specific language url}}">`{% endraw %}, then user will be always redirected to english version (from `'/'` to `'/en/'`). To avoid this, it is needed to write information about choosen language to user cookies. It can be done using builtin django [set_language](https://docs.djangoproject.com/en/dev/topics/i18n/translation/#the-set-language-redirect-view) view.
