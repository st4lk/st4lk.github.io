---
layout: post
title:  "Django logging settings"
date:   2013-09-26 18:19:43 +0000
categories: django logging
redirect_from:
  - /2013/django-logging-settings/
  - /blog/2013/09/26/django-logging-settings.html
---

<div class="gist-wrp"><div class="github-btn" id="github-btn" style="float:right;"> <a class="gh-btn" id="gh-btn" href="https://gist.github.com/st4lk/6725777" target="_blank"> <span class="gh-ico"></span> <span class="gh-text" id="gh-text">Gist</span> </a></div></div>

Let's look at default django logging settings and try to make them more useful.

Here what we have in settings.py after command `django-admin.py startproject project_name` (django 1.5):

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

As it written in comments, logger 'django.request' will sent email message to admins on every HTTP 500 error (they are in fact uncaught exceptions) when DEBUG=False. Email list is set in `settings.ADMINS`.

But, that's not all. There are also default settings, they are set in `django.utils.log.DEFAULT_LOGGING`. Here how they look like for version 1.5.4 (actual version can be found on [github](https://github.com/django/django/blob/master/django/utils/log.py)):


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

### What do they mean?

Logger 'django' writes all logs from child loggers to console with message level WARNING and higher ('level' for logger 'django' is not set, by default it is WARNING). Child loggers are: 'django.db.backends', 'django.contrib.gis' and so on. But except 'django.request' which has 'propagate': False.

Logger 'py.warnings' also writes messages from module [warnings](http://docs.python.org/2/library/warnings.html) into console. For example DeprecationWarnings.

### Example of useful (to my mind) config

For simplicity only one root logger can be defined, that will catch logs from all modules. If `settings.DEBUG = True` it will write messages to console and into special debug log-file. And if `settings.DEBUG = False`, messages will be written only in production log-file, with level INFO and higher only.

When `settings.DEBUG = True` all SQL queries will be written in console and in debug log-file, that is very useful. If you wish, it is possible to define separate logger 'django.db' with 'propagate': False and set to it needed settings.

As i define root logger, other loggers will have empty handlers list, to not duplicate messages.

Source at [gist.github](https://gist.github.com/st4lk/6725777)

<script src="https://gist.github.com/st4lk/6725777.js"></script>

#### Settings will work with django 1.5+

For earlier django version it is probably needed co create file log.py somewhere:

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

And use path to this file for `NullHandler`, `RequireDebugTrue`, `RequireDebugFalse` instead of `django.utils.log. ...`.

Now you can do in any source file:

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

and all your logs will be processed, depending on DEBUG.
