---
layout: post
title:  "Отладка SQL в django тестах"
date:   2015-03-04 18:19:43 +0000
categories: database django logging sql
redirect_from:
  - /2015/debug-sql-django-test/
---

[![Отладка SQL в django тестах](https://img-fotki.yandex.ru/get/4517/85893628.c67/0_1795f5_a958c090_orig.png "Отладка SQL в django тестах")]({{ site.baseurl }}{{ page.url }})

В django тестах можно замерять количество сделанных SQL запросов:

```python
def test_home(self):
    with self.assertNumQueries(1):
        response = self.client.get('/')
    self.assertEqual(response.status_code, 200)
```

Если код в контексте `assertNumQueries` сделает иное количество обращений к БД, чем ожидается (здесь 1), то тест выдает ошибку. Но когда такой тест не проходит, бывает трудно определить лишний отправленный запрос. Для отладки такого случая удобно вывести в консоль отправленные SQL запросы. Далее опишу, как этого добиться.

<!--more-->

Кстати, если вы используете Django 1.7+, то вместе с ошибкой будут показаны все SQL выражения, т.е. если этого достаточно - то делать вообще ничего не надо. Ура! Если же вы используете более старые версии, то данная статья будет полезна.

### Настройка логов для вывода SQL запросов в консоль

Django будет логировать SQL запрос, если соблюдается одного из следующих условий:

```python
settings.DEBUG = True
```

или

```python
connection.use_debug_cursor = True
```

По умолчанию в тестах всегда *DEBUG = False* вне зависимости от того, что стоит в вашем *settings.DEBUG*. Это правильно, тестировать лучше с боевыми настройками.

Т.о. остается *connection.use_debug_cursor*, которое по умолчанию всегда *None* или *False* (в разных версиях по разному). Но контекстный менеджер *assertNumQueries* сам выставляет это значение в *True* на время работы соответствующего блока! Нам остается лишь правильно задать настройки логов.

Создадим отдельный файл настроек для тестов и назовем его settings_test.py. Тесты гонять будем с ним. Рекомендую всегда делать так - это удобно. Структура проекта примерно такая:

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

Файл tests.py содержит тесты приложения spam. Так организовывать тесты не самый хороший выбор, лучше выделить отдельную папку и держать все тесты там. Но для простоты нашего примера годится.

Содержимое settings_test.py:

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

Тест (tests.py) выглядит так:

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

Давайте посмотрим, что будет при прогоне теста используя разные runner'ы.

#### Django 1.4+

`$ python manage.py test` (нет SQL):

```bash
Creating test database for alias 'default'...
.
----------------------------------------------------------------------
Ran 1 test in 0.009s

OK
Destroying test database for alias 'default'...
```

`$ python manage.py test  --settings=project.settings_test` (SQL в консоле)

```bash
Creating test database for alias 'default'...
(0.000) SELECT "spam_foo"."id", "spam_foo"."title" FROM "spam_foo" LIMIT 21; args=()
.
----------------------------------------------------------------------
Ran 1 test in 0.009s

OK
Destroying test database for alias 'default'...
```

#### Django 1.4+ и django-nose

- pip install django-nose
- в settings.py выставляем *TEST_RUNNER = 'django_nose.NoseTestSuiteRunner'*

`$ python manage.py test` (нет SQL):

```bash
...
```

`$ python manage.py test  --settings=project.settings_test` (SQL в консоле)

```bash
(0.000) SELECT "spam_foo"."id", "spam_foo"."title" FROM "spam_foo" LIMIT 21; args=()
...
```


#### Django 1.4+ и pytest-django

- pip install pytest-django
- создаем файл pytest.ini рядом с manage.py и задаем файл настроек:    

```bash
    [pytest]
    DJANGO_SETTINGS_MODULE = project.settings
```

- переименуем tests.py в test_spam.py (стандартные имена для py.test)

`$ py.test` (нет SQL):

```bash
...
```

`$ py.test  --ds=project.settings_test` (нет SQL, py.test перехватывает весь вывод)

```bash
...
```

`$ py.test  --ds=project.settings_test -s` (SQL в консоле)

```sql
(0.000) SELECT "spam_foo"."id", "spam_foo"."title" FROM "spam_foo" LIMIT 21; args=()
...
```

#### Итого

Как видно из предыдущих примеров, при использовании нашего settings_test в консоль выводятся все запросы к БД, сделанные в блоке контекстного менеджера *assertNumQueries*.

Если мы хотим гонять тесты всегда с этими настройками, а не только когда хотим что-то отладить, то очень скоро устанем от обилия SQL. Можно сделать так: закомментировать строчку `'handlers': ['console'],`, т.о. ничего выводится не будет. А когда нужно их посмотреть - просто убираем комментарий.

### Вывод ошибки assertNumQueries и Django 1.7+

Если *assertNumQueries* регистрирует отличное от ожидаемого количество обращений к БД, то выводится traceback и ошибка:

```python
Traceback (most recent call last):
  ...
AssertionError: 1 queries executed, 2 expected
```

Но в django 1.7+ так же выводятся и сделанные запросы:

```sql
Captured queries were:
QUERY = u'SELECT "spam_foo"."id", "spam_foo"."title" FROM "spam_foo" LIMIT 21' - PARAMS = ()
```

Как вы понимаете, настройки логов на это не влияют, очень удобно!

### Вывод всех SQL запросов в консоль не используя assertNumQueries

До сих пор речь шла об использовании *assertNumQueries*. Но что если нужно посмотреть запросы вне этого менеджера?

Для этого нужно самому выставить `connection.use_debug_cursor = True` перед прогоном тестов. Это можно сделать в test runner'е или используя специальный hook в py.test.

#### SQL во всех тестах: Django 1.4+

Создаем файл test_runner.py, кладем его рядом с settings.py и вставляем такой код:

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

Теперь либо в settings (или settings_test, если используем его для тестов) указываем наш runner:

```python
TEST_RUNNER = 'project.test_runner.SqlDebugTestSuiteRunner'
```

Запускаем `python manage.py test --settings=project.settings_test` и видим все запросы, созданные за время тестов.

Либо можно не задавать *TEST_RUNNER*, а использовать аргумент *--testrunner*:

`python manage.py test --settings=project.settings_test --testrunner=project.test_runner.SqlDebugTestSuiteRunner`

Результат будет тем же.

#### SQL во всех тестах: Django 1.4+ и django-nose

Для nose почти все так же, только runner нужно унаследовать от NoseTestSuiteRunner.

test_runner.py:

```python
from django_nose import NoseTestSuiteRunner
from django.db import connections, DEFAULT_DB_ALIAS

class SqlDebugTestSuiteRunner(NoseTestSuiteRunner):
    def setup_test_environment(self, **kwargs):
        super(SqlDebugTestSuiteRunner, self).setup_test_environment(**kwargs)
        connections[DEFAULT_DB_ALIAS].use_debug_cursor = True
```

Да, на момент написания статьи версия django-nose==1.3. В этой версии не поддерживается аргумент *--testrunner*. Но я отправил [пул реквест](https://github.com/django-nose/django-nose/pull/187), возможно, он уже попал в релиз.

#### SQL во всех тестах: Django 1.4+ и pytest-django

В py.test все немного по другому, ведь там не используется стандартный runner из django. Вместо этого для установления тестового окружения можно использовать py.test хуки.

Создаем файл plugin_debug_sql.py, кладем рядом с settings.py, вставляем код:

```python
def pytest_runtest_setup(item):
    from django.db import connections, DEFAULT_DB_ALIAS
    connections[DEFAULT_DB_ALIAS].use_debug_cursor = True
```

Запускать так:

```PYTHONPATH=`pwd`:$PYTHONPATH py.test -s --ds=sql.settings_test -p project.plugin_debug_sql```

Тут я явно добавляю текущую папку в PYTHONPATH, потому что иначе py.test не сможет найти наш плагин.
