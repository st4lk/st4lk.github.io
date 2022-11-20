---
layout: post
title:  "Python function with mutable default arguments"
date:   2013-03-05 18:19:43 +0000
categories: python
redirect_from:
  - /2013/python-mutable-default-arguments/
---

[![Python mutable default arguments](/assets/images/posts/2013-03-05-python-mutable-default-arguments/jellyfish-1.jpeg "Python mutable default arguments")]({{ site.baseurl }}{{ page.url }})

In python default function arguments are created during executing instruction def and not at each function call. If argument value is immutable object (for example string, integer, tuple) it is ok, but if value is mutable, then there can be a trap:

```python
def foo(l=[]):
    l.append('x')
    return l
```

It seems, that every call to foo() will return list ['x']. But:
<!--more-->

```python
>>> foo()
['x']
>>> foo()
['x', 'x']
>>> foo()
['x', 'x', 'x']
```

So, if it is needed to create empty list at every call, you should do:

```python
def bar(l=None):
    if l is None:
        l = []
    l.append('x')
    return l
```

However, sometimes this behaviour can be usefull. Here is a way to know function call count:

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
