---
layout: post
title:  "Настройки логов для django"
date:   2013-09-26 18:19:43 +0000
categories: django logging
redirect_from:
  - /2013/django-logging-settings/
---

<div class="gist-wrp"><div class="github-btn" id="github-btn" style="float:right;"> <a class="gh-btn" id="gh-btn" href="https://gist.github.com/st4lk/6725777" target="_blank"> <span class="gh-ico"></span> <span class="gh-text" id="gh-text">Gist</span> </a></div></div>

Рассмотрим дефолтные настройки логов в django и попробуем их сделать максимально удобными.

Вот что есть в settings.py после команды `django-admin.py startproject project_name` (django 1.5):

<!--more-->

```python
# A sample logging configuration. The only tangible logging
# performed by this configuration is to send an email to
# the site admins on every HTTP 500 error when DEBUG=False.
# See http://docs.djangoproject.com/en/dev/topics/logging for
# more details on how to customize your logging configuration.
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'filters': {
        'require_debug_false': {
            '()': 'django.utils.log.RequireDebugFalse'
        }
    },
    'handlers': {
        'mail_admins': {
            'level': 'ERROR',
            'filters': ['require_debug_false'],
            'class': 'django.utils.log.AdminEmailHandler'
        }
    },
    'loggers': {
        'django.request': {
            'handlers': ['mail_admins'],
            'level': 'ERROR',
            'propagate': True,
        },
    }
}
```

Как и написано в коментарии, здесь определяется логгер, который будет отсылать сообщения на email всем админам при возникновении ошибки HTTP 500 (по сути это любое неперехваченное исключение - exception), при условии, что `settings.DEBUG = False`. Список email'ов определен в `settings.ADMINS`.

Однако, это не все. Есть еще дефолтные настройки, они определены в `django.utils.log.DEFAULT_LOGGING`. Так они выглядят для версии 1.5.4 (актуальную версию можно посмотреть на [github](https://github.com/django/django/blob/master/django/utils/log.py)):


```python
DEFAULT_LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'filters': {
        'require_debug_false': {
            '()': 'django.utils.log.RequireDebugFalse',
        },
        'require_debug_true': {
            '()': 'django.utils.log.RequireDebugTrue',
        },
    },
    'handlers': {
        'console':{
            'level': 'INFO',
            'filters': ['require_debug_true'],
            'class': 'logging.StreamHandler',
        },
        'null': {
            'class': 'django.utils.log.NullHandler',
        },
        'mail_admins': {
            'level': 'ERROR',
            'filters': ['require_debug_false'],
            'class': 'django.utils.log.AdminEmailHandler'
        }
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
        },
        'django.request': {
            'handlers': ['mail_admins'],
            'level': 'ERROR',
            'propagate': False,
        },
        'py.warnings': {
            'handlers': ['console'],
        },
    }
}
```

### Что они означают?

Логгер 'django' пишет все логи с дочерних логгеров в консоль с уровнем сообщений WARNING и выше ('level' для логгера 'django' не задан, а по умолчанию он равен WARNING). Дочерние логгеры такие: 'django.db.backends', 'django.contrib.gis' и т.д. Но кроме 'django.request', у которого стоит 'propagate': False.

Логгер 'py.warnings' так же пишет сообщения от модуля [warnings](http://docs.python.org/2/library/warnings.html) в консоль. Например DeprecationWarnings.

### Пример удобного (на мой взгляд) конфига

Для простоты можно определить один корневой логгер, который будет собирать все сообщения со всех модулей. Если `settings.DEBUG = True`, то он будет писать в консоль и в специальный отладочный лог-файл все сообщения. Если же `settings.DEBUG = False`, то сообщения будут писаться только в продакшн лог-файл, только с уровнем INFO и выше.

При `settings.DEBUG = True` будут выводиться в консоль и писаться в лог-файл все SQL запросы, что очень удобно. При желании можно создать отдельный логгер 'django.db' с 'propagate': False и задать ему нужные настройки.

Т.к. тут я определил корневой логгер, остальным логгерам ставлю null handler, чтобы сообщения не дублировались.

Код на [gist.github](https://gist.github.com/st4lk/6725777)

<script src="https://gist.github.com/st4lk/6725777.js"></script>

#### Настройки будут работать для django 1.5+

Для более ранних версий django можно создать файл log.py:

```python
import logging
from django.conf import settings


try:
    from logging import NullHandler
except ImportError:
    class NullHandler(logging.Handler):
        def emit(self, record):
            pass


class RequireDebugTrue(logging.Filter):
    def filter(self, record):
       return settings.DEBUG


class RequireDebugFalse(logging.Filter):
    def filter(self, record):
        return not settings.DEBUG
```

И использовать пути для `NullHandler`, `RequireDebugTrue`, `RequireDebugFalse` из этого файла, вместо `django.utils.log. ...`.

Теперь, в любом файле можно сделать так:

```python
import logging
logger = logging.getLogger(__name__)

logger.debug("some message")
logger.warning("oops, it is a warning")
logger.error("bad, very bad")

try:
    # do something
except ValueError:
    logger.exception("I know it could happen")
```

и все ваши логи попадут в нужное место, в зависимости от DEBUG.
