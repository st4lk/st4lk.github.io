---
layout: post
title:  "Python logging на каждый день"
date:   2013-08-20 18:19:43 +0000
categories: python logging
redirect_from:
  - /2013/python-logging-every-day/
  - /blog/2013/08/20/python-logging-every-day.html
---

<div class="gist-wrp"><div class="github-btn" id="github-btn" style="float:right;"> <a class="gh-btn" id="gh-btn" href="https://gist.github.com/st4lk/6287746" target="_blank"> <span class="gh-ico"></span> <span class="gh-text" id="gh-text">Gist</span> </a></div></div>

В процессе написания программы, скрипта, часто бывает нужно вывести какую-либо отладочную информацию или сообщить о каком-то событии. Известно, что для этих целей есть встроенный модуль [logging](http://docs.python.org/library/logging.html). Однако обычно у меня бывает так: времени в обрез, а все эти настройки логов (handlers, loggers, formatters и пр.) никак не могу запомнить, и на скорую руку вставляю просто print. Потом, если скрипт используется часто или его надо отдать заказчику - хочется чтобы все эти сообщения записывались в файл для последующего анализа. И приходится все переделывать с использованием logging. Так вот, чтобы не держать в голове все настройки логирования, пишу этот пост с необходимыми для работы параметрами.

<!--more-->

### Требования к логированию будут такие:

- Все логи пишутся в файл и выводятся в консоль (дублируются)
- Файл логов ротируется (не превышает указанный размер)
- Все логи используемых библиотек так же обрабатываются (в логах видно, что это сообщения из библиотеки, а не из скрипта)
- Работает на python 2.5+ 3.0+
- В записи лога есть: само сообщение, имя логгера, имя файла, номер строки, дата, уровень сообщения (DEBUG/INFO/WARNING и т.д.)
- В лог можно записывать unicode строки

### Как пользоваться этими настройками

В [сниппете](https://gist.github.com/st4lk/6287746) приведены три типа настроек: путем определения logging классов, используя [fileConfig](http://docs.python.org/2/library/logging.config.html#logging.config.fileConfig) и используя [dictConfig](http://docs.python.org/2/library/logging.config.html#logging.config.dictConfig). Выберите какой вам больше нравится. Самый простой - первый, который использует классы. Так же он работает на большинстве версий python'a: 2.5+, 3.0+. Вставьте настройки в ваш скрипт - и у вас настроено логгирование. Теперь все лог-сообщения будут выводиться на консоль и в файл.

### В коде задаются параметры для корневого (root) логгера.

Он стоит на вершине иерархии логгеров и соответственно к нему попадают сообщения со всех других логгеров (для полного понимания модуля logging лучше почитать статьи в интернете. Например, есть очень хороший туториал прямо в документации python'a: [http://docs.python.org/2/howto/logging.html#logging-basic-tutorial](http://docs.python.org/2/howto/logging.html#logging-basic-tutorial)).

#### Пример

Возьмем простейший скрипт:

```python
import logging

logging.info('started')
logging.info('finished')
```

Если запустим скрипт в таком виде, то ничего никуда не напечатается.

Добавим теперь настройки из моего сниппета (используя классы):

```python
###############################################
#### LOGGING CLASS SETTINGS (py25+, py30+) ####
###############################################
#### also will work with py23, py24 without 'encoding' arg
import logging
import logging.handlers
f = logging.Formatter(fmt='%(levelname)s:%(name)s: %(message)s '
    '(%(asctime)s; %(filename)s:%(lineno)d)',
    datefmt="%Y-%m-%d %H:%M:%S")
handlers = [
    logging.handlers.RotatingFileHandler('rotated.log', encoding='utf8',
        maxBytes=100000, backupCount=1),
    logging.StreamHandler()
]
root_logger = logging.getLogger()
root_logger.setLevel(logging.DEBUG)
for h in handlers:
    h.setFormatter(f)
    h.setLevel(logging.DEBUG)
    root_logger.addHandler(h)
##############################
#### END LOGGING SETTINGS ####
##############################

logging.info('started')
logging.info('finished')
```

Запустим скрипт. В консоль (и в файл rotated.log) напечатались сообщения:

```bash
INFO:root: started (2013-08-21 01:52:31; test.py:21)
INFO:root: finished (2013-08-21 01:52:31; test.py:22)
```

Проверим, выводятся ли сообщения из сторонних библиотек. Для простоты создадим игрушечную библиотеку `thirdpartylib` с кодом:

```python
import logging
logger = logging.getLogger(__name__)

def do_something():
    logger.debug('something is done in thirdpartylib')
```

Теперь в нашем скрипте вызовем `do_something`:

```python
import thirdpartylib

logging.info('started')
thirdpartylib.do_something()
logging.info('finished')
```

Вывод будет таким:

```bash
INFO:root: started (2013-08-21 01:57:27; test.py:135)
DEBUG:thirdpartylib: something is done in thirdpartylib (2013-08-21 01:57:27; __init__.py:5)
INFO:root: finished (2013-08-21 01:57:27; test.py:137)
```

Сам сниппет:

<script src="https://gist.github.com/st4lk/6287746.js"></script>
