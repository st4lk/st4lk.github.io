---
layout: post
title:  "Подключение celery к django"
date:   2014-11-02 18:19:43 +0000
categories: django celery
redirect_from:
  - /2014/django-celery-setup/
---

[![Подключение celery к django](/assets/images/posts/2014-11-02-django-celery-setup/2and5_celery_420.jpeg "Подключение celery к django")]({{ site.baseurl }}{{ page.url }})

Для подключения [celery](http://www.celeryproject.org/) к новому проекту так или иначе приходится подглядывать в предыдущие, чтобы вспомнить необходимые шаги: какие настройки задавать, как запускать, как останавливать и т.д.

Хочу собрать все в одном месте.

<!--more-->

### Что нужно получить в итоге

1. Посредством celery добавить возможность django проекту выполнять задачи в фоне, чтобы не загружать текущий python процесс. Пример таких задач: отправка емейлов, работа со сторонним апи, долгие вычисления и т.д.
2. В качестве брокера используем [redis](http://redis.io/).
3. В админке нужно видеть все запущенные и выполненные задачи.
4. В админке нужно видеть статус текущих воркеров celery (online/offline).

### Подключаем celery

#### Установим redis

Для того, чтобы процессы django и celery могли общаться между собой, нужен посредник (broker), который будет передавать сообщения. В качестве этого брокера будем использовать redis. Это распространенное решение, redis быстр, легко устанавливается, требует мало памяти, надежен. Список всех возможных посредников можно посмотреть [здесь](http://celery.readthedocs.org/en/latest/getting-started/brokers/#broker-overview).

На всякий случай проверим сервер (все примеры на ubuntu):

```bash
sudo apt-get update
sudo apt-get install build-essential
sudo apt-get install tcl8.5
```

Скачиваем последнюю версию [отсюда](http://redis.io/download/). На момент написания статьи это версия 2.8.17

```bash
wget http://download.redis.io/releases/redis-2.8.17.tar.gz
tar xzf redis-2.8.17.tar.gz
cd redis-2.8.17
make
make test
sudo make install
cd utils
sudo ./install_server.sh
```

Запускаем redis сервер

```bash
sudo service redis_6379 start
```

Если что, остановить его можно так

```bash
sudo service redis_6379 stop
```

Чтобы redis запускался при загрузке системы, выполним команду

```bash
sudo update-rc.d redis_6379 defaults
```

Так же нам понадобится python драйвер для redis, установим его:

```bash
pip install redis
```

#### Установка и настройка django-celery

В принципе, сelery и django можно подружить не используя специальной библиотеки, следуя инструкциям из [документации](http://docs.celeryproject.org/en/latest/django/first-steps-with-django.html). Однако, для удобной интеграции celery в админку django проще установить специальное приложение [django-celery](https://pypi.python.org/pypi/django-celery) (см. [почему](http://docs.celeryproject.org/en/latest/django/first-steps-with-django.html#using-the-django-orm-cache-as-a-result-backend)).

```bash
pip install django-celery
```

Добавляем такие настройки в settings.py:

```python
INSTALLED_APPS += ("djcelery", )

# адрес redis сервера
BROKER_URL = 'redis://localhost:6379/0'
# храним результаты выполнения задач так же в redis
CELERY_RESULT_BACKEND = 'redis://localhost:6379/0'
# в течение какого срока храним результаты, после чего они удаляются
CELERY_TASK_RESULT_EXPIRES = 7*86400  # 7 days
# это нужно для мониторинга наших воркеров
CELERY_SEND_EVENTS = True
# место хранения периодических задач (данные для планировщика)
CELERYBEAT_SCHEDULER = "djcelery.schedulers.DatabaseScheduler"

# в конец settings.py добавляем строчки
import djcelery
djcelery.setup_loader()
```

Создаем таблицы в базе. Eсли используем south, то

```bash
$ python manage.py migrate djcelery
```

А если нет, то обычный syncdb

```bash
$ python manage.py syncdb
```

#### Создание задач

Задачи создаются в файле `tasks.py`, который нужно положить в папочку приложения:

```bash
- proj/
  - proj/__init__.py
  - proj/settings.py
  - proj/urls.py
- users/  # some app
  - users/__init__.py
  - users/models.py
  - users/views.py
  - users/tasks.py  # задачи для приложения users кладем сюда
- products/
  - products/__init__.py
  - products/models.py
  - products/views.py
  - products/tasks.py  # задачи для приложения products кладем сюда
- manage.py
```

Создадим простейшую задачу.

users/tasks.py:

```python
# -*- coding: utf-8 -*-
from celery.task import task

@task(ignore_result=True, max_retries=1, default_retry_delay=10)
def just_print():
    print "Print from celery task"
```

#### Запуск задач

##### Отладка
Для проверки работы задач запускаем

- `python manage.py runserver`  # проект django
- `python manage.py celery worker --concurrency=1`  # celery worker: процесс, который будет выполнять задачи
- `python manage.py celery beat`  # celery beat: процесс, который будет запускать периодические задачи

Последние две команды можно объединить в одну (ключик `-B`):

```bash
python manage.py celery worker -B --concurrency=1
```

Попробуем запустить нашу задачу `just_print`.
Условно можно выделить 2 способа вызова задачи:

1. Планировщиком задач, вызывать через определенный интервал времени (например, каждые 10 секунд) или в определенное время (аналогично crontab)
2. Из кода, в нужном месте и при нужных условиях

##### Вызов задачи планировщиком

Заходим в админку по адресу [http://{host}/admin/djcelery/periodictask/](http://127.0.0.1:8000/admin/djcelery/periodictask/) и нажимаем "Add periodic task".
Заполняем поля как на фото ниже и сохраняем.

[![Создание периодичной задачи каждые 10 секунд](https://img-fotki.yandex.ru/get/2714/85893628.c66/0_15fe67_b0ad7288_XL.png
 "Создание периодичной задачи каждые 10 секунд")](https://img-fotki.yandex.ru/get/2714/85893628.c66/0_15fe67_b0ad7288_orig.png)

Для указания времени запуска, вместо интервала, делаем все то же самое, что и в предыдущем случае, только вместо Interval указываем Crontab:

[![Создание периодичной задачи в начале каждой минуты](https://img-fotki.yandex.ru/get/6700/85893628.c66/0_15fe66_8c4b6564_XL.png
 "Создание периодичной задачи в начале каждой минуты")](https://img-fotki.yandex.ru/get/6700/85893628.c66/0_15fe66_8c4b6564_orig.png)

##### Замечание

Периодические задачи можно создать автоматически при запуске проекта (при запуске процесса celery), чтобы не делать этого через админку вручную (но в админке они так же будут видны). Для этого их нужно указать в settings.py.

Каждые 10 секунд:

```python
CELERYBEAT_SCHEDULE = {
    'example-task': {
        'task': 'apps.users.tasks.just_print',
        'schedule': 10,  # в секундах, или timedelta(seconds=10)
    },
}
```

Раз в минуту (задача будет запускаться в 0 секунд каждой минуты):

```python
from celery.schedules import crontab
CELERYBEAT_SCHEDULE = {
    'example-task': {
        'task': 'apps.users.tasks.just_print',
        'schedule': crontab(),
    },
}
```

Или например каждую 7-ю минуту каждого часа:

```python
from celery.schedules import crontab
CELERYBEAT_SCHEDULE = {
    'example-task': {
        'task': 'apps.users.tasks.just_print',
        'schedule': crontab(minute=7),
    },
}
```

Подробности про создание периодических задач в settings.py в [документации celery](http://celery.readthedocs.org/en/latest/userguide/periodic-tasks.html).

Так же, можно пометить функцию декоратором `@periodic_task` вместо `@task`, и эта задача станет периодической. Период задается аргументом run_every, в качестве значения ему передается то же самое, что и для ключа 'schedule' в CELERYBEAT_SCHEDULE:

```python
from celery.task import periodic_task

@periodic_task(ignore_result=True, run_every=10)  # 10 секунд, или timedelta(seconds=10)
def just_print():
    print "Print from celery task"
```

или crontab

```python
from celery.task import periodic_task
from celery.schedules import crontab

@periodic_task(ignore_result=True, run_every=crontab())  # раз в минуту
def just_print():
    print "Print from celery task"
```

##### Вызов задачи из кода

Для вызова задачи из кода используется метод [`.delay()`](http://celery.readthedocs.org/en/latest/userguide/calling.html#basics). Например, из view:

```python
from .tasks import just_print

class UserListView(ListView):
    model = User

    def get_context_data(self, **kwargs):
        just_print.delay()
        return super(UserListView, self).get_context_data(**kwargs)
```

#### Мониторинг

В админке в секции Djcelery видим строки [Tasks](http://127.0.0.1:8000/admin/djcelery/taskstate/) и [Workers](http://127.0.0.1:8000/admin/djcelery/workerstate/).

[![Djcelery в админке](https://img-fotki.yandex.ru/get/6819/85893628.c66/0_15fe68_a4352d4f_XL.png
 "Djcelery в админке")](https://img-fotki.yandex.ru/get/6819/85893628.c66/0_15fe68_a4352d4f_orig.png)

Однако, сейчас они пустые. Чтобы там была информация о текущем состоянии воркеров и задач, нужно запустить celerycam:

```bash
python manage.py celerycam --frequency=10.0
```

Теперь видим, что у нас работает 1 воркер:

[![Статус воркера в админке](https://img-fotki.yandex.ru/get/3301/85893628.c66/0_15fe6b_a74622e4_XL.png
 "Статус воркера в админке")](https://img-fotki.yandex.ru/get/3301/85893628.c66/0_15fe6b_a74622e4_orig.png)

И видим статус выполнения задач:

[![Статус выполнения задач в админке](https://img-fotki.yandex.ru/get/2914/85893628.c66/0_15fe6a_49533167_XL.png
 "Статус выполнения задач в админке")](https://img-fotki.yandex.ru/get/2914/85893628.c66/0_15fe6a_49533167_orig.png)

По умолчанию, celerycam удаляет старые задачи из Tasks по таким правилам:

- сборщик запускается с интервалом 1 час (см. [код celery 3.1](https://github.com/celery/celery/blob/3.1/celery/events/snapshot.py#L40), способа поменять этот интервал из настроек не нашел)
- в каждом вызове сборщик удаляет задачи, превышающие установленное время жизни.

Время жизни отчетов по задачам можно задать настройками в settings.py (ниже приведены значения по умолчанию):

```python
from datetime import timedelta

CELERYCAM_EXPIRE_SUCCESS = timedelta(days=1)
CELERYCAM_EXPIRE_ERROR = timedelta(days=3)
CELERYCAM_EXPIRE_PENDING = timedelta(days=5)
```

#### Запуск в продакшн

В продакшне процессы celery должны быть daemon'ами.

Для запуска/остановки всех процессов celery можно написать отдельный bash скрипт, а можно запускать с помощью supervisor. Итак, по порядку.

##### Bash скрипты

Запуск, celery_start.sh:

```bash
#!/bin/bash
PYTHON=/path/to/bin/python
PROJECT_FOLDER=/project_dir/project/
PID_FOLDER=/path/to/pid/
LOGS_FOLDER=/path/to/logs/
BEAT_SHEDULE_FILE=/path/to/shedule/celerybeat-schedule  # celery beat need to store the last run times of the tasks in a local database file

$PYTHON ${PROJECT_FOLDER}manage.py celery worker --concurrency=1 --detach --pidfile=${PID_FOLDER}celery_worker.pid --logfile=${LOGS_FOLDER}celery_worker.log
$PYTHON ${PROJECT_FOLDER}manage.py celery beat --detach --pidfile=${PID_FOLDER}celery_beat.pid --logfile=${LOGS_FOLDER}celery_beat.log -s ${BEAT_SHEDULE_FILE}
$PYTHON ${PROJECT_FOLDER}manage.py celerycam --frequency=10.0 --detach --pidfile=${PID_FOLDER}celerycam.pid --logfile=${LOGS_FOLDER}celerycam.log
```

Остановка, celery_stop.sh:

```bash
#!/bin/bash
PYTHON=/path/to/bin/python
PID_FOLDER=/path/to/pid/

$PYTHON -m celery multi stopwait worker1 --pidfile=${PID_FOLDER}celerycam.pid
$PYTHON -m celery multi stopwait worker1 --pidfile=${PID_FOLDER}celery_beat.pid
$PYTHON -m celery multi stopwait worker1 --pidfile=${PID_FOLDER}celery_worker.pid
```

#### supervisord

Лучше всего запустить celery процессы под контролем [supervisord](http://supervisord.org/).

Для этого создаем где-нибудь у себя в проекте такие файлы (например, в папке deploy):

supervisor.celeryd.conf

```bash
[program:djangoproject.celeryd]
command=/path/to/bin/python /path/to/django_project/manage.py celeryd --concurrency=1
user=www-data
numprocs=1
directory=/path/to/django_project
stdout_logfile=/path/to/log/celery_worker.log
stderr_logfile=/path/to/log/celery_worker.log
autostart=true
autorestart=true
startsecs=10
stopwaitsecs = 120
priority=998
```

supervisor.celerybeat.conf

```bash
[program:djangoproject.celerybeat]
command=/path/to/bin/python /path/to/django_project/manage.py celery beat -s /path/to/celerybeat-schedule
user=www-data
numprocs=1
directory=/path/to/django_project
stdout_logfile=/path/to/log/celery_beat.log
stderr_logfile=/path/to/log/celery_beat.log
autostart=true
autorestart=true
startsecs=10
stopwaitsecs = 120
priority=998
```

supervisor.celerycam.conf

```bash
[program:djangoproject.celerycam]
command=/path/to/bin/python /path/to/django_project/manage.py celerycam --frequency=10.0
user=www-data
numprocs=1
directory=/path/to/django_project
stdout_logfile=/path/to/log/celerycam.log
stderr_logfile=/path/to/log/celerycam.log
autostart=true
autorestart=true
startsecs=10
stopwaitsecs = 120
priority=998
```

Заменяем все `/path/to/` на нужные для конкретного проекта, а так же указываем нужного юзера, под которым будут запускаться процессы celery.

Теперь создадим symlink на наши файлы конфигурации в папке /etc/supervisor/conf.d/, чтобы supervisor знал о них:

```bash
cd /etc/supervisor/conf.d
sudo ln -s /path/to/django_project/deploy/supervisor.celeryd.conf
sudo ln -s /path/to/django_project/deploy/supervisor.celerybeat.conf
sudo ln -s /path/to/django_project/deploy/supervisor.celerycam.conf
```

И перезапустим supervisor

```bash
sudo supervisorctl reload
```

Проверим, что все нужные процессы запущены:

```bash
ps aux | grep python
```

#### Прочее

Если в админке зайти в периодические задачи ([http://{host}/admin/djcelery/periodictask/](http://127.0.0.1:8000/admin/djcelery/periodictask/)), то увидим там celery.backend_cleanup:

[![celery.backend_cleanup](https://img-fotki.yandex.ru/get/10/85893628.c66/0_15fe69_fe0539e0_XL.png
 "celery.backend_cleanup")](https://img-fotki.yandex.ru/get/10/85893628.c66/0_15fe69_fe0539e0_orig.png)

Эта задача подчищает все устаревшие результаты задач, которые хранятся в базе данных. Устаревшие - это те, которые старше указанного нами интервала времени в `settings.CELERY_TASK_RESULT_EXPIRES`. Но, т.к. результаты задач мы храним в redis, а не в базе данных, то данная периодическая задача нам не важна. Т.о. ее можно удалить. Redis сама удаляет те значения, время жизни которых истекло.
