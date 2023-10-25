---
layout: post
title:  "Django проект: с нуля до работающего сервера"
date:   2013-11-13 18:19:43 +0000
categories: django deploy
redirect_from:
  - /2013/django-project-beginning-working-server/
  - /blog/2013/11/13/django-project-beginning-working-server.html
---

В этом посте хочу описать свой опыт создания и запуска django проекта на VPS-хостинге.

Разделим задачу на этапы:

1. Создание django-проекта
2. Настройка деплоя
3. Настройка сервера (установка нужных библиотек)
4. Деплой проекта

<!--more-->

### Создание django-проекта

Итак. Пусть наш проект называется myproject. Создадим его на локальном компьютере. Будем считать, что python у нас в системе установлен. Для начала нам понадобятся pip и virtualenv (если еще не стоят).

Создаем виртуальное окружение:

```bash
virtualenv venv-myproject
```

Активируем его:

```bash
# on *nix system
source venv-myproject/bin/activate

REM on windows
venv\Scripts\activate.bat
```

Далее нужно создать заготовку (минимально необходимые файлы проекта). Самый простой вариант - установить django и использовать команду django-admin.py startproject. Так создастся совсем базовый набор файлов. Нужно будет еще много вещей доделывать руками, это долго. Лучше иметь свой шаблон, где уже определены все наиболее часто используемые настройки, библиотеки. Для этих целей существуют разные утилиты, мне нравится [cookiecutter](https://github.com/audreyr/cookiecutter). Я взял за основу [cookiecutter шаблон для django](https://github.com/pydanny/cookiecutter-django) и создал свой: [https://github.com/st4lk/cookiecutter-django](https://github.com/st4lk/cookiecutter-django).

Для начала установим cookiecutter:

```bash
pip install cookiecutter
```

Теперь создадим django проект из шаблона:

```bash
cookiecutter https://github.com/st4lk/cookiecutter-django.git
```

После этого в консоле будут заданы вопросы (название проекта, имя и т.д.) и создание заготовки проекта готово.

Работаем над проектом локально, тестим его.

И вот пришло время запустить проект на сервере. Но наш сервер пока представляет из себя голую операционную систему, в которую необходимо установить утилиты и библиотеки для работы веб приложения. Я буду описывать сервер с ОС Ubuntu.

### Настройка деплоя

Решил осветить этот вопрос до настройки сервера, т.к. способ деплоя будет влиять на все дальнейшие действия. Как-то я принимал проект, который использовал утилиту makesite. Она мне понравилась, использую ее и сейчас для некоторых проектов. Будет использоваться связка nginx, uwsgi, supervisor.

Cсылки:

- проект на github: [https://github.com/klen/makesite](https://github.com/klen/makesite)
- описание процесса от создателя утилиты: [http://klen.github.io/deploy-setup-ru.html](http://klen.github.io/deploy-setup-ru.html)

makesite умеет создавать, обновлять, удалять проект на сервере.

При создании проекта makesite создает все необходимое окружение автоматически, основываясь на специальных шаблонах. В окружение входит: создание virtualenv, настройка nginx, uwsgi, supervisor, инициализация БД. Т.е. все необходимое, чтобы проект работал. Команда создания проекта:

```bash
makesite install <project_name>
```

где `<project_name>` - название нашего проекта. Позднее мы будем пользоваться этим названием для обновления.

Процесс обновления (деплоя) выглядит так. Мы разрабатываем проект локально, коммитим. При этом мы имеем внешний репозиторий на каком-либо сервере. Это может быть github, bitbucket или же свой собственный. В какой-то момент мы решаем обновить проект на сервере. Для этого мы push'им проект в наш внешний репозиторий. Далее, заходим по ssh на наш сервер (production сервер, на котором проект работает) и вводим такую команду:

```bash
makesite update <project_name>
```

Все, проект обновился. Makesite обновил код на сервере из репозитория, установил новые зависимости, выполнил миграции для БД, перезапустил Nginx. Все эти действия записаны в bash скриптах makesite'а и при желании их можно изменять, удалять, добавлять.

#### Настройка makesite

1. Создаем файл makesite.ini. Назовем его "главный", чтобы не путаться, т.к. будет еще один. Вот шаблон для него:

    ```
    [Main]
    # режим 'продакшн'
    mode=project
    # домен нашего сервера, будет использован например для создания файла конфигурации nginx
    domain=example.com
    # имя пользователя БД postgres (для создания базы проекта)
    pguser=postgres
    # пароль пользователя БД postgres
    pgpassword=secret_password
    # имя базы данных проекта
    dbname=project_name
    # имя пользователя базы проекта
    dbuser=project_user
    # пароль пользователя базы проекта
    dbpassword=project_user_password
    # адрес процесса postgres. Скорее всего это менять не надо.
    pghost=127.0.0.1
    # адрес нашего внешнего репозитория
    src=git+git@bitbucket.org:username/example.git
    # пользователь, от которого makesite будет осуществлять свои действия
    src_user=root
    ```
2. Создаем в корневой папке нашего проекта еще один файл makesite.ini, назовем его "дополнительный":

    ```
    [Main]
    template=virtualenv,db-postgres,django,uwsgi
    django_settings=<project_name.settings>
    ```

где `<project_name.settings>` заменяем на путь к модулю settings, относительно файла manage.py. Здесь именно python путь, т.е. используем `.`, а не `/`.

Дефолтные настройки для uwsgi, nginx и supervisor: [https://github.com/klen/makesite/tree/master/makesite/templates/uwsgi/deploy](https://github.com/klen/makesite/tree/master/makesite/templates/uwsgi/deploy).

Если понадобиться их изменить, мы добавляем такие строки к текущему makesite.ini (дополнительному)

```
[Templates]
uwsgi=%(source_dir)s/deploy/makesite_templates/uwsgi
```

Создаем директорию 'deploy/makesite_templates' в нашем проекте, копируем туда папку `uwsgi` отсюда: [https://github.com/klen/makesite/tree/master/makesite/templates](https://github.com/klen/makesite/tree/master/makesite/templates). Затем ищем и изменяем нужные нам конфигурационные файлы тут: 'deploy/makesite_templates/uwsgi/deploy/'

Итого у нас имеется

- главный makesite.ini (его пока держим в сторонке, его нужно будет положить на сервер)
- дополнительный makesite.ini, который лежит в корне проекта
- если нужно, то папка deploy/makesite_templates/uwsgi с измененными настройками nginx, uwsgi, supervisor. Эта папка так же лежит в проекте.

Не забываем положить под git все это добро и сделать push на внешний репозиторий.

### Настройка сервера

Все команды проверял для дистрибутива Ubuntu 12.04. В качестве базы данных будет использовать postgresql. Поехали.

Заходим на сервер под root'ом.

Проверяем версию python:

```python
python -V
```

Далее я предполагаю, что python версии 2.7.

```bash
# Мы зашли под root'ом
# Первым делом обновим систему
apt-get update
apt-get upgrade

# Утилиты для сборки
apt-get install build-essential
apt-get install libpq-dev

# Конфигурирование локалей
locale-gen ru_RU.UTF-8
locale-gen en_US.UTF-8
dpkg-reconfigure locales

# Установка git
apt-get install git

# Устанавливаем setup-tools
apt-get install python-setuptools python-pip

# Исходники python2.7 для сборки библиотек
apt-get install python2.7-dev

# На всякий случай
apt-get install python-dev

# Устоновка postgres
apt-get install postgresql

# правим файл
# /etc/postgresql/{postgres_version}/main/pg_hba.conf
# строку
# "local   all             postgres                                peer"
# Меняем на
# "local   all             postgres                                md5"

# Настройка postgres
sudo -u postgres psql template1
# Установка пароля для юзера postgres
\password postgres
# !!! Вводим пароль и запоминаем его
# нажимаем ctrl+d чтобы выйти

# Полезности для postgres
apt-get install pgagent
apt-get install pgadmin3

# Если нужно изменить какие-либо настройки, обновляем конфиг (только если знаем, что делаем):
# /etc/postgresql/{postgres_version}/main/postgresql.conf
# где {postgres_version} = версия postgres.
# Перезапусаем postgres
/etc/init.d/postgresql restart

# Установка uwsgi
pip install uwsgi

# Установка nginx, virtualenv, supervisor
easy_install elementtree
apt-get install python-virtualenv nginx supervisor

# Скорее всего это понадобиться для работы с изображениями
apt-get install libjpeg-dev
pip install -I Pillow

# Создаем отдельный ssh ключ на сервере, который будет использовать makesite
cd
test -d .ssh || mkdir .ssh
cd ~/.ssh
ssh-keygen
# На вопрос "Enter file in which to save the key" пишем makesite
# На остальные просто enter, т.е. как-то так:

  Generating public/private rsa key pair.
  Enter file in which to save the key (/home/ubuntu/.ssh/id_rsa): makesite
  Enter passphrase (empty for no passphrase):
  Enter same passphrase again:
  Your identification has been saved in makesite.
  Your public key has been saved in makesite.pub.

# Копируем ключ в id_rsa
cp makesite id_rsa
cp makesite.pub id_rsa.pub

# ! Важно
# Берем публичный ключ makesite.pub и добавляем его в список доступа нашего репозитория (который на github или bitbucket или на собственном сервере)
# Описание с github: https://help.github.com/articles/generating-ssh-keys#step-3-add-your-ssh-key-to-github
# Скорее всего команда 'clip' (из github описания) не будет найдена, поэтому просто копируем содержимое файла makesite.pub "ручками"

# Создаем директорию для хранения наших будущих сайтов
mkdir /var/www

# Кладем наш "главный" makesite.ini в /var/www

# Устанавливаем makesite
pip install makesite

# Выводим и проверяем настройки bash
makesite shell -p /var/www
# Записываем их в ваш ~/.bashrc
cat >> ~/.bashrc
# копируем и вставляем вывод предыдущей команды
# он примерно такой:

# Makesite integration
# ====================
export MAKESITE_HOME=/var/www
source /usr/local/lib/python2.7/dist-packages/makesite/shell.sh

# enter
# ctrl+d для выхода
# Загружаем настройки для текущего сеанса
source ~/.bashrc

# Если вдруг у вас есть зависимости в requirements.txt
# для которых нужно скачать репозиторий с помощью mercurial
# например что-то такое:
# -e hg+https://bitbucket.org/psam/django-postman/@92ede1fd0c32f4e5acc6c78b25804dc047267d3e#egg=django_postman-dev
# то нужно установить mercurial
apt-get install mercurial

# Устанавливаем проект (занимает время, может минут 5)
# предварительно изменив <project_name> на название нашего проекта
# Это название будем использовать позднее при обновлении проекта
makesite install <project_name>

# Если вывелась строчка
# OPERATION SUCCESSFUL
# то все ок, если нет - смотрим ошибку

# На всякий случай проверим, установились ли библиотеки из requirements.txt:
cd /var/www/{project_name}/master
source .virtualenv/bin/activate
pip freeze
# смотрим, установились ли зависимости из requirements.txt

# Так же можно проверить, создались ли таблицы и применились ли миграции.

# Убедитесь, что STATIC_ROOT и MEDIA_ROOT имеют верные значения
# соответствующие папки должны быть тут:
# /var/www/{project_name}/master/
# если каких-то папок не хватает, то можно создать их вручную
# указав владельца и группу www-data

# обновим статику (предполагается, что virtualenv активирована):
cd /var/www/{project_name}/master/source 
python manage.py collectstatic --noinput

# На всякий случай перезапустим nginx
/etc/init.d/nginx restart
```

Все, проект запущен и работает.

### Деплой проекта

Как уже говорилось, для обновления проекта действия такие:

- делаем push в наш репозиторий
- заходим на сервер по ssh и вводим `makesite update <project_name>`
