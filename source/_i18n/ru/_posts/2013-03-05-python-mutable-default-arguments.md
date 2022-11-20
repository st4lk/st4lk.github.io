---
layout: post
title:  "Функции с изменяемыми значениями по умолчанию в python'e"
date:   2013-03-05 18:19:43 +0000
categories: python
redirect_from:
  - /2013/python-mutable-default-arguments/
---

[![Python mutable default arguments](/assets/images/posts/2013-03-05-python-mutable-default-arguments/jellyfish-1.jpeg "Python mutable default arguments")]({{ site.baseurl }}{{ page.url }})

В python'е значения функции по умолчанию создаются в момент выполнения инструкции def, а не при каждом вызове функции. Если значение - неизменяемый объект (например строка, целое число, кортеж), то никаких подводных камней здесь нет. А вот если объект изменяемый (например список), то есть возможность попасть в ловушку. Вот пример:

```python
def foo(l=[]):
    l.append('x')
    return l
```

Казалось бы, при каждом вызове foo() будет возвращаться список ['x']. Но:
<!--more-->

```python
>>> foo()
['x']
>>> foo()
['x', 'x']
>>> foo()
['x', 'x', 'x']
```

Поэтому, если нужно, чтобы при каждом вызове создавался новый пустой список, следует делать так:

```python
def bar(l=None):
    if l is None:
        l = []
    l.append('x')
    return l
```

Однако, иногда этот эффект может быть полезен. Вот способ узнать сколько раз функция была вызвана:

```python
from itertools import count

def bar(call_count=count()):
    return next(call_count)

>>> bar()
0
>>> bar()
1
>>> bar()
2
>>> bar()
3
```
