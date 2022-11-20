---
layout: post
title:  "Отладка django проекта с помощью встроенного python отладчика pdb"
date:   2012-11-18 18:19:43 +0000
categories: django python sublime
redirect_from:
  - /2012/debug-django-project-embedded-python-debugger-pdb/
---

Я использую [sublime-text](http://www.sublimetext.com/) в качестве редактора python кода. В нем нет встроенного отладчика, поэтому для отладки django проектов я в основном делал так:

```python
print var_name
```

и в консоле локального сервера смотрел вывод команды. Я использую этот метод и сейчас, но иногда хочется пройтись по коду по шагам, посмотреть все переменные.

Это можно сделать с помощью встроенного python отладчика pdb:

```python
import pdb; pdb.set_trace()
```

<!--more-->

Т.е. мы вставляем эту строку в то место в коде, где мы хотим остановиться. Это брейкпоинт. Теперь обновим страницу проекта в браузере. Когда код проекта дойдет до этой строки, браузер замрет, а в консоле локального сервера появиться:

```python
(Pdb)
```

Мы попали в отладчик и теперь можем вводить [комманды](http://docs.python.org/2/library/pdb.html#debugger-commands), например такие:

- l - посмотреть, где мы находимся
- n - (step next) сделать шаг вперед, не входя внутрь функции
- s - (step in) сделать шаг внутрь, т.е. если стоим на вызове функции, войдем внутрь
- r - (step out) продолжить выполнение до конца текущего блока. Например, мы стоим внутри цикла, вводим r и попадаем на первую после цикла строку.
- c - продолжить выполнение до следующего брейкпоинта, т.е. до `pdb.set_trace()`
- p - выполнить питон код, или просто показать переменную: `p var_name`

## Пример

Допустим у нас есть такой view:

![view](/assets/images/posts/2012-11-18-debug-django-project-embedded-python-debugger-pdb/view.jpeg "view")

Вставим `import pdb; pdb.set_trace()` в нужное место и запустим локальный сервер, если не запущен:

![view_pdb](/assets/images/posts/2012-11-18-debug-django-project-embedded-python-debugger-pdb/view_pdb.jpeg "view_pdb")

В браузере обратимся к странице, которая вызывает этот view. Страница замерла:

![browser_hang](/assets/images/posts/2012-11-18-debug-django-project-embedded-python-debugger-pdb/browser_hang.jpeg "browser_hang")

В консоле видим (Pdb):

![pdb_console](/assets/images/posts/2012-11-18-debug-django-project-embedded-python-debugger-pdb/pdb_console.jpeg "pdb_console")

Посмотрим, где мы, командой `l`:

![pdb_l](/assets/images/posts/2012-11-18-debug-django-project-embedded-python-debugger-pdb/pdb_l.jpeg "pdb_l")

Сделаем два шага веред командой `n`:

![pdb_nn](/assets/images/posts/2012-11-18-debug-django-project-embedded-python-debugger-pdb/pdb_nn.jpeg "pdb_nn")

Посмотрим значение переменных `about` и `about.content`:

![pdb_p](/assets/images/posts/2012-11-18-debug-django-project-embedded-python-debugger-pdb/pdb_p.jpeg "pdb_p")

Продолжим выполнение командой `c`:

![pdb_c](/assets/images/posts/2012-11-18-debug-django-project-embedded-python-debugger-pdb/pdb_c.jpeg "pdb_c")

Страница отобразилась в браузере:

![browser_done](/assets/images/posts/2012-11-18-debug-django-project-embedded-python-debugger-pdb/browser_done.jpeg "browser_done")
