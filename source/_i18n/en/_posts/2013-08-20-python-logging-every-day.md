---
layout: post
title:  "Python logging for every day"
date:   2013-08-20 18:19:43 +0000
categories: python logging
redirect_from:
  - /2013/python-logging-every-day/
---

<div class="gist-wrp"><div class="github-btn" id="github-btn" style="float:right;"> <a class="gh-btn" id="gh-btn" href="https://gist.github.com/st4lk/6287746" target="_blank"> <span class="gh-ico"></span> <span class="gh-text" id="gh-text">Gist</span> </a></div></div>

When writing a small python program or script, it is sometimes needed to output debug message or maybe event. It is known, that python has [logging](http://docs.python.org/library/logging.html) module exactly for that purpose. But in my case usually such thing happens: it is lack of time and hands just writes `print` instead of logging, because i can't remember all those complicated logging settings. But then, if script is launched often or i must provide it to customer, i have to replace all prints with logging, because it is better to log all messages to file. So, not to keep in my head all these settings, i am writing this post.

<!--more-->

### Logging requirements will be the following:

- All logs must be written to file and in console (duplicated)
- Log file is rotated (not exceed specified size)
- All third party libraries logs are also handled
- Works on python 2.5+ 3.0+
- Log message contains: message, logger name, source file name, source file line, timestamp, message level (DEBUG/INFO/WARNING etc)
- It is possible to log unicode strings.

### How to use these settings

In [snippet](https://gist.github.com/st4lk/6287746) there are three types of settings: using logging classes, with [fileConfig](http://docs.python.org/2/library/logging.config.html#logging.config.fileConfig) and with [dictConfig](http://docs.python.org/2/library/logging.config.html#logging.config.dictConfig). Choose whatever you like. The most simple is the first, it works on most python versions: 2.5+, 3.0+. Insert those settings in your script - and you logging is set up. Now all log messages are stored to file and are printed to console.

### In code logging options are set for root logger

It stands at the top of loggers hierarchy and consequently it handles all messages from every logger (for better understanding of logging module you can search posts in internet. For example, there is good tutorial in python documentation: [http://docs.python.org/2/howto/logging.html#logging-basic-tutorial](http://docs.python.org/2/howto/logging.html#logging-basic-tutorial)).

#### Example

Lets write simple script:

```python
import logging

logging.info('started')
logging.info('finished')
```

If run it as is, messages will not be printed anywhere.

Now add settigns from my snippet (using classes):

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

Run the script. In console (and in file rotated.log) we can see messages:

```bash
INFO:root: started (2013-08-21 01:52:31; test.py:21)
INFO:root: finished (2013-08-21 01:52:31; test.py:22)
```

Check, that logs from used libs are also handled. I create dummy lib `thirdpartylib` with code:

```python
import logging
logger = logging.getLogger(__name__)

def do_something():
    logger.debug('something is done in thirdpartylib')
```

Now call `do_something` from your script:

```python
import thirdpartylib

logging.info('started')
thirdpartylib.do_something()
logging.info('finished')
```

Output will be the following:

```bash
INFO:root: started (2013-08-21 01:57:27; test.py:135)
DEBUG:thirdpartylib: something is done in thirdpartylib (2013-08-21 01:57:27; __init__.py:5)
INFO:root: finished (2013-08-21 01:57:27; test.py:137)
```

Snippet:

<script src="https://gist.github.com/st4lk/6287746.js"></script>
