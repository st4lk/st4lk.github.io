---
layout: post
title:  "Debug SQL in django test"
date:   2015-03-04 18:19:43 +0000
categories: database django logging sql
redirect_from:
  - /2015/debug-sql-django-test/
---

[![Debug SQL in django test](https://img-fotki.yandex.ru/get/4517/85893628.c67/0_1795f5_a958c090_orig.png "Debug SQL in django test")]({{ site.baseurl }}{{ page.url }})

In django tests we can measure number of sql queries:

```python
def test_home(self):
    with self.assertNumQueries(1):
        response = self.client.get('/')
    self.assertEqual(response.status_code, 200)
```

If code in context of `assertNumQueries` will make other number of DB attempts than expected (here 1), test will throw error. But when test fails it is sometimes hard to understand, what unexpected query was made. To debug such case very useful to log SQL expressions to console. Below is description how to do it.

<!--more-->

By the way, in Django 1.7+ when test fails all SQL queries will be also printed. So we don't need to do anything else! If you use older version of django, then this article will be helpful.

### Logging settings for SQL output in console

Django will log SQL attempt only if one of the following condition is met:

```python
settings.DEBUG = True
```

or

```python
connection.use_debug_cursor = True
```

By default tests always have *DEBUG = False* regardless of your *settings.DEBUG*. Testing is good with real environment.

So we are left with *connection.use_debug_cursor*, that is *None* or *False* by default (depending on version). But context manager *assertNumQueries* set this to *True* by itself for corresponding code block! We just need to set logging correctly.

Create file settings_test.py. We'll run tests with settings from this file, i recommend to do so.

Project structure:

```bash
project
├── project
│   ├── __init__.py
│   ├── settings.py
│   ├── settings_test.py
│   ├── urls.py
│   └── wsgi.py
│
├── spam  # some app
│   ├── __init__.py
│   ├── views.py
│   ├── tests.py
│   └── models.py
│
└── manage.py
```

Module tests.py contains tests of spam app. It is not the best way to organise the app, better to create separate folder for tests, but for our simple example it is ok.

settings_test.py:

```python
from settings import *
try:
    from settings import LOGGING
except ImportError:
    LOGGING = dict(version=1, disable_existing_loggers=False,
        handlers={}, loggers={})

# use database in memory to not lose your data!
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': ':memory:',
        'USER': '',
        'PASSWORD': '',
        'TEST_CHARSET': 'utf8',
    }}

LOGGING['handlers']['console'] = {
    'level': 'DEBUG',
    'class': 'logging.StreamHandler',
}
LOGGING['loggers']['django.db.backends'] = {
    'handlers': ['console'],
    'level': 'DEBUG',
    'propagate': False,
}
LOGGING['loggers']['django.db.backends.schema'] = {
    'propagate': False,  # don't log schema queries, django >= 1.7
}
```

tests.py:

```python
from django.test import TestCase
from spam.models import Foo

class SpamTestCase(TestCase):
    def setUp(self):
        Foo.objects.create(title="Foo")

    def test_home(self):
        with self.assertNumQueries(1):
            response = self.client.get('/')
        self.assertEqual(response.status_code, 200)
```

Let's see what we get using different test runners.


#### Django 1.4+

`$ python manage.py test` (no SQL):

```bash
Creating test database for alias 'default'...
.
----------------------------------------------------------------------
Ran 1 test in 0.009s

OK
Destroying test database for alias 'default'...
```

`$ python manage.py test  --settings=project.settings_test` (SQL in console)

```bash
Creating test database for alias 'default'...
(0.000) SELECT "spam_foo"."id", "spam_foo"."title" FROM "spam_foo" LIMIT 21; args=()
.
----------------------------------------------------------------------
Ran 1 test in 0.009s

OK
Destroying test database for alias 'default'...
```

#### Django 1.4+ and django-nose

- pip install django-nose
- in settings.py set *TEST_RUNNER = 'django_nose.NoseTestSuiteRunner'*

`$ python manage.py test` (no SQL):

```bash
...
```

`$ python manage.py test  --settings=project.settings_test` (SQL в консоле)

```sql
(0.000) SELECT "spam_foo"."id", "spam_foo"."title" FROM "spam_foo" LIMIT 21; args=()
...
```

#### Django 1.4+ and pytest-django

- pip install pytest-django
- create file pytest.ini next to manage.py and put following lines in it:    

```bash
[pytest]
DJANGO_SETTINGS_MODULE = project.settings
```

- rename tests.py to test_spam.py (default name pattern in py.test)

`$ py.test` (no SQL):

```bash
...
```

`$ py.test  --ds=project.settings_test` (no SQL, py.test capture entire output)

```bash
...
```

`$ py.test  --ds=project.settings_test -s` (SQL in console)

```sql
(0.000) SELECT "spam_foo"."id", "spam_foo"."title" FROM "spam_foo" LIMIT 21; args=()
...
```

#### Summary

As we can see from previous examples, SQL from block *assertNumQueries* are logged to console when we use settings_test.

If we'll always run tests with such settings we soon become tired from all this SQL being printed. To avoid this just comment line `'handlers': ['console'],`. And when you need to see SQL - uncomment it.


### Error output from assertNumQueries and Django 1.7+

If *assertNumQueries* registers not expected number of database attempts then we get a traceback with an error:

```python
Traceback (most recent call last):
  ...
AssertionError: 1 queries executed, 2 expected
```

But in django 1.7+ along with this we get SQL queries being made:

```sql
Captured queries were:
QUERY = u'SELECT "spam_foo"."id", "spam_foo"."title" FROM "spam_foo" LIMIT 21' - PARAMS = ()
```

Logging settings have to effect to this, very useful!

### Show SQL outside of assertNumQueries

So far we were talking about *assertNumQueries*, but what if we need to check queries outside of this manager? 

It is needed to manually set `connection.use_debug_cursor = True` before tests. It can be done in test runner or using hook in py.test.

#### Show all SQL: Django 1.4+

Create file test_runner.py, put it next to settings.py and insert code:

```python
try:
    from django.test.runner import DiscoverRunner as DjangoTestSuiteRunner
except ImportError:
    # django < 1.6
    from django.test.simple import DjangoTestSuiteRunner
from django.db import connections, DEFAULT_DB_ALIAS

class SqlDebugTestSuiteRunner(DjangoTestSuiteRunner):
    def setup_test_environment(self, **kwargs):
        super(SqlDebugTestSuiteRunner, self).setup_test_environment(**kwargs)
        connections[DEFAULT_DB_ALIAS].use_debug_cursor = True
```

Now either in settings (or settings_test if you use it) set runner:

```python
TEST_RUNNER = 'project.test_runner.SqlDebugTestSuiteRunner'
```

Launch `python manage.py test --settings=project.settings_test` and see all SQL attempts made during test run.

Either not set *TEST_RUNNER* and use *--testrunner* argument:

`python manage.py test --settings=project.settings_test --testrunner=project.test_runner.SqlDebugTestSuiteRunner`

Result will be the same.

#### Show all SQL: Django 1.4+ and django-nose

For nose mostly everything is the same, but runner should sublcass NoseTestSuiteRunner.

test_runner.py:

```python
from django_nose import NoseTestSuiteRunner
from django.db import connections, DEFAULT_DB_ALIAS

class SqlDebugTestSuiteRunner(NoseTestSuiteRunner):
    def setup_test_environment(self, **kwargs):
        super(SqlDebugTestSuiteRunner, self).setup_test_environment(**kwargs)
        connections[DEFAULT_DB_ALIAS].use_debug_cursor = True
```

At the time when i write this post version of django-nose is 1.3. In this version argument *--testrunner* is not supported. I've send [pull request](https://github.com/django-nose/django-nose/pull/187), it could fall in release already.

#### Show all SQL: Django 1.4+ and pytest-django

In py.test we must go another way, as it doesn't use standard django runner. Instead we create a hook to set test environment.

Create file plugin_debug_sql.py, put it next to settings.py, paste code:

```python
def pytest_runtest_setup(item):
    from django.db import connections, DEFAULT_DB_ALIAS
    connections[DEFAULT_DB_ALIAS].use_debug_cursor = True
```

Launch by such command:

```PYTHONPATH=`pwd`:$PYTHONPATH py.test -s --ds=sql.settings_test -p project.plugin_debug_sql```

I have to put current path explicitly in PYTHONPATH here, as py.test won't do it automatically for some reason.
