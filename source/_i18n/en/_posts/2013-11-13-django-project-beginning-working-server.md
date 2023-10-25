---
layout: post
title:  "Django project: from beginning to working server"
date:   2013-11-13 18:19:43 +0000
categories: django deploy
redirect_from:
  - /2013/django-project-beginning-working-server/
  - /blog/2013/11/13/django-project-beginning-working-server.html
---

In this post i'll describe my experience of deploying django project to VPS-hosting.

Steps of deploying and server setup:

1. Creation of django project
2. Deploy setup
3. Server setup
4. Deploy

<!--more-->

### Creation of django project

Assume, that project is called myproject.

First, create it on local machine. We'll need pip and virtualenv (if not installed yet).

Create virtual environment:

```bash
virtualenv venv-myproject
```

Acitvate it:

```bash
# on *nix system
source venv-myproject/bin/activate

REM on windows
venv\Scripts\activate.bat
```

Next it is need to create a django project skeleton. We can just install django and use command 'django-admin.py startproject'. This will create a very basic and poor project. Many time will be needed to add common used things, settings. Very useful to have your own template of a project with common used settings. I like [cookiecutter](https://github.com/audreyr/cookiecutter), it is easy to use. You can take this template [https://github.com/pydanny/cookiecutter-djangopackag](https://github.com/pydanny/cookiecutter-django) and modify it. Here is my: [https://github.com/st4lk/cookiecutter-django](https://github.com/st4lk/cookiecutter-django).

Install cookiecutter:

```bash
pip install cookiecutter
```

Create django project from template (my template for example):

```bash
cookiecutter https://github.com/st4lk/cookiecutter-django.git
```

After this you'll see question in console (project name, etc.). Initial project creation is done.

Then we work with project locally.

At some moment we are ready to deploy it. But currently our server has just OS installed and nothing else. Lets fix that (i'll describe server with ubuntu).

### Deploy setup

I deside to talk about deploy now, because it will affect all other actions.

Once i was working with project, that used **makesite** utility for deploy. I like it and use it with some of my projects.

Links:

- project at github: [https://github.com/klen/makesite](https://github.com/klen/makesite)
- description from author (in russian): [http://klen.github.io/deploy-setup-ru.html](http://klen.github.io/deploy-setup-ru.html)

makesite can install, update, unistall project on server.

At project creation makesite create all nessesary environment automatically, based on specific templates. Environment includes: creation of virtualenv, nginx configuration, uwsgi, supervisor, database initialization. So all the project needs to be started. Project install command:

```bash
makesite install <project_name>
```

When we need to deploy a project, we push it to remote repository (that is hosted on github, bitbucket or any other server). Then, we access our server by ssh (were project is launched) and enter such command:

```bash
makesite update <project_name>
```

Thats all, the project is updated.

#### makesite configuration

1. Create makesite.ini. Lets call it "main", as we'll have another one.

    ```
    [Main]
    # production mode
    mode=project
    # project domain, will be used in nginx config
    domain=example.com
    # postgres superuser (for database creation)
    pguser=postgres
    # postgres superuser password
    pgpassword=secret_password
    # database name
    dbname=project_name
    # postgres user, that will have access to database (same, as in django settings.py)
    dbuser=project_user
    # postgres user password
    dbpassword=project_user_password
    # postgres host name
    pghost=127.0.0.1
    # remote repository address
    src=git+git@bitbucket.org:username/example.git
    # user, the makesite will work from
    src_user=root
    ```
2. Create in root folder of project file makesite.ini, we'll call it "additional":

    ```
    [Main]
    template=virtualenv,db-postgres,django,uwsgi
    django_settings=<project_name.settings>
    ```

where `<project_name.settings>` is path to settings module, relative to 'manage.py'. It is needed to use `.`, not `/`.

Default settings for uwsgi, nginx and supervisor will be taken from [https://github.com/klen/makesite/tree/master/makesite/templates/uwsgi/deploy](https://github.com/klen/makesite/tree/master/makesite/templates/uwsgi/deploy).

If you need to customize them, add following lines to "additional" makesite.ini

```
[Templates]
uwsgi=%(source_dir)s/deploy/makesite_templates/uwsgi
```

Create path 'deploy/makesite_templates' in your project, copy `uwsgi` dir from [https://github.com/klen/makesite/tree/master/makesite/templates](https://github.com/klen/makesite/tree/master/makesite/templates). Then modify needed configs here 'deploy/makesite_templates/uwsgi/deploy/'

In summary we hanve:

- main makesite.ini (we'll need it later on server)
- additional makesite.ini, that is placed in project root
- path deploy/makesite_templates/uwsgi if required.

Don't forget to put all this stuff (except main makesite.ini) under git and push the changes..

### Server setup

All commands are checked for Ubuntu 12.04.

Access server with root account.

Check python version:

```python
python -V
```

I assert, that it is 2.7

```bash
# We are root
# Update the system
apt-get update
apt-get upgrade

# Compilation utils
apt-get install build-essential
apt-get install libpq-dev

# Config locale
locale-gen ru_RU.UTF-8
locale-gen en_US.UTF-8
dpkg-reconfigure locales

# git setup
apt-get install git

# setup-tools
apt-get install python-setuptools python-pip

# Another compilation packages
apt-get install python2.7-dev
apt-get install python-dev

# postgres setup
apt-get install postgresql

# modify /etc/postgresql/{postgres_version}/main/pg_hba.conf
# line
# "local   all             postgres                                peer"
# change to
# "local   all             postgres                                md5"

sudo -u postgres psql template1
#postgres superuser password
\password postgres
# !!! enter password and remember it
# press ctrl+d to exit

# postgres utils
apt-get install pgagent
apt-get install pgadmin3

#If you need to customize postgres settings, modify this file:
# /etc/postgresql/{postgres_version}/main/postgresql.conf
# Restart postgres
/etc/init.d/postgresql restart

# uwsgi
pip install uwsgi

# nginx, virtualenv, supervisor
easy_install elementtree
apt-get install python-virtualenv nginx supervisor

# working with images
apt-get install libjpeg-dev
pip install -I Pillow

# Create ssh key, that will be used by makesite
cd
test -d .ssh || mkdir .ssh
cd ~/.ssh
ssh-keygen
#"Enter file in which to save the key": makesite
# Other question just hit enter:

  Generating public/private rsa key pair.
  Enter file in which to save the key (/home/ubuntu/.ssh/id_rsa): makesite
  Enter passphrase (empty for no passphrase):
  Enter same passphrase again:
  Your identification has been saved in makesite.
  Your public key has been saved in makesite.pub.

# Copy to id_rsa
cp makesite id_rsa
cp makesite.pub id_rsa.pub

# ! Important
# Tak public key makesite.pub and add it to your remote repository.
# Description from github: https://help.github.com/articles/generating-ssh-keys#step-3-add-your-ssh-key-to-github

# Create path, where project will be placed
mkdir /var/www

# Put "main" makesite.ini into /var/www

# makesite setup
pip install makesite

# Check bash settings
makesite shell -p /var/www
# Write them into ~/.bashrc
cat >> ~/.bashrc
# copy and paste previous output
# it was something like:

# Makesite integration
# ====================
export MAKESITE_HOME=/var/www
source /usr/local/lib/python2.7/dist-packages/makesite/shell.sh

# enter
# ctrl+d to exit
# load settings for current session
source ~/.bashrc

# it is useful
apt-get install mercurial

# Now install project. It takes some time.
makesite install <project_name>

# If you see message
# OPERATION SUCCESSFUL
# at the end, then installation is done successfully.

# Check, that dependencies are installed from requirements.txt:
cd /var/www/{project_name}/master
source .virtualenv/bin/activate
pip freeze

# Check, that database is create, tables are synced, migration are applied.

# Check, that STATIC_ROOT and MEDIA_ROOT have right values.
# corresponding folders must be placed here:
# /var/www/{project_name}/master/
# if some folders are missed, you can create in manuall
# but change owner and group to www-data

# update static
# (virtualenv must be activated)
cd /var/www/{project_name}/master/source 
python manage.py collectstatic --noinput

# Restart nginx
/etc/init.d/nginx restart
```

Thats all, project is launched.

### Deploy

As it written before, to update a project make:

- push to remote repo
- access server by ssh and from server type `makesite update <project_name>`
