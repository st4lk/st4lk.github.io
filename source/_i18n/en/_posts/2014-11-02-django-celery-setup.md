---
layout: post
title:  "Django celery setup"
date:   2014-11-02 18:19:43 +0000
categories: django celery
redirect_from:
  - /2014/django-celery-setup/
  - /blog/2014/11/02/django-celery-setup.html
---

[![Django celery setup](/assets/images/posts/2014-11-02-django-celery-setup/2and5_celery_420.jpeg "Django celery setup")]({{ site.baseurl }}{{ page.url }})

To enable [celery](http://www.celeryproject.org/) in new django project i often look in previous ones to refresh in my memory some steps: what settings should be specified, how to launch, how to stop and so on.

Here i want to combine all together in one place.

<!--more-->

### What we must get as a result

1. Add delayed task executing in django project, controlled by celery, to not load current django process. Examples of such tasks: email sending, working with third party api, heavy processing and etc.
2. Use [redis](http://redis.io/) as a broker.
3. In admin we can see launched and finished tasks.
4. In admin we can see status of all workers (online/offline).

### Celery setup

#### Install redis

To be able to exchange messages between processes we need a broker, that will hold those messages. I choose redis, as it is common solution, it fast, easy to install, low memory usage, reliable. List of all possible brokers can be found [here](http://celery.readthedocs.org/en/latest/getting-started/brokers/#broker-overview).

Just in case let's check our server (all examples for ubuntu):

```bash
sudo apt-get update
sudo apt-get install build-essential
sudo apt-get install tcl8.5
```

Download [last version](http://redis.io/download/). When i wrote this post, it was 2.8.17.

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

Start redis server

```bash
sudo service redis_6379 start
```

We can stop it by command

```bash
sudo service redis_6379 stop
```

Start redis at system boot up

```bash
sudo update-rc.d redis_6379 defaults
```

Also we'll need a redis driver for python, install it

```bash
pip install redis
```

#### Install django-celery

In fact, it is not necessary to install some special django app to add celery functionality, as it written in [docs](http://docs.celeryproject.org/en/latest/django/first-steps-with-django.html). But for usefull integration with django admin it is easier to install [django-celery](https://pypi.python.org/pypi/django-celery) (look [why](http://docs.celeryproject.org/en/latest/django/first-steps-with-django.html#using-the-django-orm-cache-as-a-result-backend)).

```bash
pip install django-celery
```

Add following configuration to settings.py:

```python
INSTALLED_APPS += ("djcelery", )

# redis server address
BROKER_URL = 'redis://localhost:6379/0'
# store task results in redis
CELERY_RESULT_BACKEND = 'redis://localhost:6379/0'
# task result life time until they will be deleted
CELERY_TASK_RESULT_EXPIRES = 7*86400  # 7 days
# needed for worker monitoring
CELERY_SEND_EVENTS = True
# where to store periodic tasks (needed for scheduler)
CELERYBEAT_SCHEDULER = "djcelery.schedulers.DatabaseScheduler"

# add following lines to the end of settings.py
import djcelery
djcelery.setup_loader()
```

Task are defined in `tasks.py`file, that is placed in app folder:

```bash
- proj/
  - proj/__init__.py
  - proj/settings.py
  - proj/urls.py
- users/  # some app
  - users/__init__.py
  - users/models.py
  - users/views.py
  - users/tasks.py  # users tasks lives here
- products/
  - products/__init__.py
  - products/models.py
  - products/views.py
  - products/tasks.py  # products tasks lives here
- manage.py
```

Create simplest task.

users/tasks.py:

```python
# -*- coding: utf-8 -*-
from celery.task import task

@task(ignore_result=True, max_retries=1, default_retry_delay=10)
def just_print():
    print "Print from celery task"
```

#### Launch task

##### Debugging

To check, that tasks are working, start

- `python manage.py runserver`  # django project
- `python manage.py celery worker --concurrency=1`  # celery worker: process, that will do the tasks
- `python manage.py celery beat`  # celery beat: process, that will execute periodic tasks

Last two commands can be combined into one (key `-B`):

```bash
  python manage.py celery worker -B --concurrency=1
```

Let's try to launch our task `just_print`.

There are two ways to start a task:

1. By scheduler, that will call the task every time period (10 seconds for example) or every particular time (like crontab do).
2. From code, in needed place and under needed conditions.

##### Launch task by scheduler

Go to admin page at address [http://{host}/admin/djcelery/periodictask/](http://127.0.0.1:8000/admin/djcelery/periodictask/) and press "Add periodic task".

Fill fields as it is shown in screenshot below and press save.

[![Launch periodic task every 10 seconds](https://img-fotki.yandex.ru/get/2714/85893628.c66/0_15fe67_b0ad7288_XL.png
 "Launch periodic task every 10 seconds")](https://img-fotki.yandex.ru/get/2714/85893628.c66/0_15fe67_b0ad7288_orig.png)

To indicate launch time instead of period, do the same, as in previous case, but fill Crontab (Interval must be blanked):

[![Launch periodic task at every new minute](https://img-fotki.yandex.ru/get/6700/85893628.c66/0_15fe66_8c4b6564_XL.png
 "Launch periodic task at every new minute")](https://img-fotki.yandex.ru/get/6700/85893628.c66/0_15fe66_8c4b6564_orig.png)

##### Note

Periodic task can be created automatically at project start (when celery process is started), to not create them manually in admin (but they still will be shown in admin). To achieve it, we can define them in settings.py.

Every 10 seconds:

```python
CELERYBEAT_SCHEDULE = {
    'example-task': {
        'task': 'apps.users.tasks.just_print',
        'schedule': 10,  # in seconds, or timedelta(seconds=10)
    },
}
```

Every new minute (will start at 0 second of every minute):

```python
from celery.schedules import crontab
CELERYBEAT_SCHEDULE = {
    'example-task': {
        'task': 'apps.users.tasks.just_print',
        'schedule': crontab(),
    },
}
```

Or for example every 7-th minute of every hour:

```python
from celery.schedules import crontab
CELERYBEAT_SCHEDULE = {
    'example-task': {
        'task': 'apps.users.tasks.just_print',
        'schedule': crontab(minute=7),
    },
}
```

For details about periodic task creation in settings.py look [celery documentation](http://celery.readthedocs.org/en/latest/userguide/periodic-tasks.html).

Also, task can be decorated with `@periodic_task` instead of `@task`. And this task will be periodic. Period is defined by `run_every` argument. Value is the same, as in 'schedule' key in CELERYBEAT_SCHEDULE:

```python
from celery.task import periodic_task

@periodic_task(ignore_result=True, run_every=10)  # 10 seconds, or timedelta(seconds=10)
def just_print():
    print "Print from celery task"
```

or crontab

```python
from celery.task import periodic_task
from celery.schedules import crontab

@periodic_task(ignore_result=True, run_every=crontab())  # every minute
def just_print():
    print "Print from celery task"
```

##### Start task from code

To start task from code call method [`.delay()`](http://celery.readthedocs.org/en/latest/userguide/calling.html#basics). For example, from view:

```python
from .tasks import just_print

class UserListView(ListView):
    model = User

    def get_context_data(self, **kwargs):
        just_print.delay()
        return super(UserListView, self).get_context_data(**kwargs)
```

#### Monitoring

In admin section Djcelery we can see rows [Tasks](http://127.0.0.1:8000/admin/djcelery/taskstate/) and [Workers](http://127.0.0.1:8000/admin/djcelery/workerstate/).

[![Djcelery in admin](https://img-fotki.yandex.ru/get/6819/85893628.c66/0_15fe68_a4352d4f_XL.png
 "Djcelery in admin")](https://img-fotki.yandex.ru/get/6819/85893628.c66/0_15fe68_a4352d4f_orig.png)

But currently they are blanked inside. To see information there about workers status and tasks history we need to start celerycam:

```bash
python manage.py celerycam --frequency=10.0
```

Now we can see, that 1 worker is online:

[![Worker status in admin](https://img-fotki.yandex.ru/get/3301/85893628.c66/0_15fe6b_a74622e4_XL.png
 "Worker status in admin")](https://img-fotki.yandex.ru/get/3301/85893628.c66/0_15fe6b_a74622e4_orig.png)

And tasks status:

[![Tasks status in admin](https://img-fotki.yandex.ru/get/2914/85893628.c66/0_15fe6a_49533167_XL.png
 "Tasks status in admin")](https://img-fotki.yandex.ru/get/2914/85893628.c66/0_15fe6a_49533167_orig.png)

By default, celerycam delete statuses of old tasks by following rules:

- collector is started every hour (look [clerey 3.1 code](https://github.com/celery/celery/blob/3.1/celery/events/snapshot.py#L40), can't find how to change it from settings.py)
- collector delete all task, that are exceed allowed life time.

Life time of task status can be defined in settings.py (default values are shown):

```python
from datetime import timedelta

CELERYCAM_EXPIRE_SUCCESS = timedelta(days=1)
CELERYCAM_EXPIRE_ERROR = timedelta(days=3)
CELERYCAM_EXPIRE_PENDING = timedelta(days=5)
```

#### Launch in production

In production all celery processes must be started as daemons.

We can run a bash script to start/stop them or define a config for supervisor.

##### Bash scripts

celery_start.sh:

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

celery_stop.sh:

```bash
#!/bin/bash
PYTHON=/path/to/bin/python
PID_FOLDER=/path/to/pid/

$PYTHON -m celery multi stopwait worker1 --pidfile=${PID_FOLDER}celerycam.pid
$PYTHON -m celery multi stopwait worker1 --pidfile=${PID_FOLDER}celery_beat.pid
$PYTHON -m celery multi stopwait worker1 --pidfile=${PID_FOLDER}celery_worker.pid
```

#### supervisord

Best practice is to launch celery processes under the control of [supervisord](http://supervisord.org/).

Create configuration for every celery process in django project, for example, in `deploy` folder:

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

Change all `/path/to/` to correct paths and also define needed user.

Now create symlink to your celery configs in /etc/supervisor/conf.d/ folder, to let supervisor know about them:

```bash
cd /etc/supervisor/conf.d
sudo ln -s /path/to/django_project/deploy/supervisor.celeryd.conf
sudo ln -s /path/to/django_project/deploy/supervisor.celerybeat.conf
sudo ln -s /path/to/django_project/deploy/supervisor.celerycam.conf
```

Restart supervisor:

```bash
sudo supervisorctl reload
```

Check, that all needed processes are started:

```bash
ps aux | grep python
```

#### Other

In periodic tasks section of admin ([http://{host}/admin/djcelery/periodictask/](http://127.0.0.1:8000/admin/djcelery/periodictask/)) we can see a celery.backend_cleanup task:

[![celery.backend_cleanup](https://img-fotki.yandex.ru/get/10/85893628.c66/0_15fe69_fe0539e0_XL.png
 "celery.backend_cleanup")](https://img-fotki.yandex.ru/get/10/85893628.c66/0_15fe69_fe0539e0_orig.png)

This task is cleaning all old task results (not statuses), that are stored in database. Old means that they were created more time ago, than defined in `settings.CELERY_TASK_RESULT_EXPIRES`. But, as we are storing task results in redis, we don't need this cleanup task. So, we can just delete it from admin page. Redis will drop all old entries by itself.
