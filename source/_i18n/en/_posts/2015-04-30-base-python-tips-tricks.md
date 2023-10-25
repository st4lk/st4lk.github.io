---
layout: post
title:  "Python tips & tricks"
date:   2015-04-30 18:19:43 +0000
categories: python
redirect_from:
  - /2015/base-python-tips-tricks/
  - /blog/2015/04/30/base-python-tips-tricks.html
---

[![Python tips & tricks](https://img-fotki.yandex.ru/get/9067/85893628.c68/0_181e3c_92d918ca_M.jpg "Python tips & tricks")]({{ site.baseurl }}{{ page.url }})

Recently i've read the book [Learning Python, 5th Edition by Mark Lutz](http://shop.oreilly.com/product/0636920028154.do).
Here is a list of most interesting insights for me.

<!--more-->

- set generation:

        {x for x in [1,2]}
        set(x for x in [1,2])
        assert set(x for x in [1,2]) == {x for x in [1,2]}

- dict generation:

        {x:x**2 for x in [1,2]}
        dict((x, x**2) for x in [1,2])
        assert {x:x**2 for x in [1,2]} == dict((x, x**2) for x in [1,2])

- division of integers

    In python 3 division of integers returns float

        >>> 1 / 2
        0.5
        >>> - 1 / 2
        -0.5

    In python 2 division of integers - round to floor, it is not truncate

        >>> 1 / 2    # 0.5 round floor -> 0
        0
        >>> - 1 / 2  # -0.5 round floor -> -1 (not 0)
        -1

    In python 2 and 3 round to floor integer division

        >>> 1 // 2
        0
        >>> - 1 // 2
        -1
        >>> 13 // 2.0
        6.0

- `is` - check, that variables point to the same address, `==` - check, that variables have same values

- python 3: `[1, 'spam'].sort()` raises exception (different types)

- python 3: dict().keys() returns iterator (view object, linked to dict). It is set-like object, we can apply set operations to it (union and so on)

        >>> dict(a=1, b=2).keys()
        dict_keys(['b', 'a'])
        >>> dict(a=1, b=2).keys() | {'c', 'd'}
        {'b', 'd', 'a', 'c'}

- frozenset - immutable set, hashable, can be used as key in dict

        >>> fz = frozenset([1,2])
        >>> fz.add(3)
        AttributeError: 'frozenset' object has no attribute 'add'
        >>> {fz: 5}
        {frozenset([1, 2]): 5}

- list support compare operators: ==, <, >, <=, >=. List compare is similiar to string compare. In py3 all objects must be the same type

        >>> [1, 2] == [1, 2]
        True
        >>> [2, 2] > [1, 2]
        True
        >>> [1] > ['sh']  # python2
        False
        >>> [1] > ['sh']  # python3
        TypeError: unorderable types: int() > str()

- dict compare

    python 2 and 3

        >>> dict(a=1) == dict(a=1)
        True

    python 2 only

        >>> dict(a=3) > dict(a=2)
        True
        >>> dict(a=3) > dict(a=2, b=1)
        False

- list + string, list + tuple is forbidden, but list += string is allowed

        >>> L = []
        >>> L + 'spam'
        TypeError: can only concatenate list (not "str") to list

        >>> L = []
        >>> L += 'spam'
        >>> L
        ['s', 'p', 'a', 'm']

- L += a is faster than L = L + a.

- L += [1,2] is in place modification! (new list is not created)

        >>> L = []
        >>> id(L)
        4368997048
        >>> L += [1,2]
        >>> id(L)
        4368997048
        >>> L = L + [1,2]
        >>> id(L)
        4368996976

- 'spam'[0][0][0] can last forever, every time we'll get single-char-string 's'

- variables unpack in python 3

        >>> a, *b = 'spam'
        >>> a
        's'
        >>> b
        ['p', 'a', 'm']

        >>> *a, b = 'spam'
        >>> a
        ['s', 'p', 'a']
        >>> b
        'm'

        >>> a, *b, c = 'spam'
        >>> a
        's'
        >>> b
        ['p', 'a']
        >>> c
        'm'

- python 2: True = 0, but not in python 3

    python 2

        >>> True = 0
        >>> True
        0

    python 3

        >>> True = 0
        SyntaxError: can't assign to keyword

- sys.stdout = open('temp.txt', 'w') - all prints goes to file temp.txt

- `and`, `or` returns object, not True/False

- `while` has `else`

- python 3: `...` is the same as `pass`

- reversed works with lists, not generator

        >>> reversed([1,2,3])
        <list_reverseiterator object at 0x10127c550>
        >>> reversed((x for x in [1,2,3]))
        TypeError: argument to reversed() must be a sequence

- zip iterates until the smallest sequence

        >>> [x for x in zip([1,2,3], [4,5])]
        [(1, 4), (2, 5)]

- python 2: map(None, s1, s2) is the same as zip, but iterates until longest sequence. Insert None for elements without pair.

    python 2

        >>> map(None, [1,2,3], [4,5])
        [(1, 4), (2, 5), (3, None)]
        >>> map(None, [1,2], [4,5,6])
        [(1, 4), (2, 5), (None, 6)]

    python 3

        >>> list(map(None, [1,2,3], [4,5]))
        TypeError: 'NoneType' object is not callable

- map can take more than one iterators (similiar to zip)

    python 2

        >>> map(lambda x, y: (x, y), [1,2], [3,4])
        [(1, 3), (2, 4)]
        >>> map(lambda x, y: (x, y), [1,2], [3,4,5])
        [(1, 3), (2, 4), (None, 5)]

    python 3

        >>> list(map(lambda x, y: (x, y), [1,2], [3,4]))
        [(1, 3), (2, 4)]
        >>> list(map(lambda x, y: (x, y), [1,2], [3,4,5]))
        [(1, 3), (2, 4)]

- nested list comprehensions

        >>> [x+y for x in 'abc' for y in 'lmn']
        ['al', 'am', 'an', 'bl', 'bm', 'bn', 'cl', 'cm', 'cn']

        # flat list of lists
        >>> csv = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
        >>> [col for row in csv for col in row]
        [1, 2, 3, 4, 5, 6, 7, 8, 9]

- sorted returns list (not generator) in py2 and py3

        >>> sorted(x for x in [2,1,3])
        [1, 2, 3]

- *args accept any iterator, not only list

- unzip: zip(*zip(a,b))

        >>> zip(*zip([1,2],[3,4]))
        [(1, 2), (3, 4)]

- py3: map returns generator, it can be iterated only once

        >>> m = map(lambda x: x, [1,2,3])
        >>> [x for x in m]
        [1, 2, 3]
        >>> [x for x in m]
        []

- py3: range is not a simple generator, it support len() and index access

        >>> r = range(10)
        >>> r
        range(0, 10)
        >>> len(r)
        10
        >>> r[3]
        3

- generator allows only single scan

- cycle import works! But only for import without from

- try has else, will be execution when no exception happened

- `with` similar to `finally`

- except (name1, name2) - orders from top to bottom, from left to right

- `except Exception:` vs `except:` - first doesn't catch system errors (KeyboardInterrupt, SystemExit, GeneratorExit например)

- set().remove(x) - removes x or KeyError, set().discard(x) - removes x or nothing

- py3.3+ accept u"", U"" for backwards compatibility with py2

- default encoding is in sys module sys.getdefaultencoding()

    python 2

        >>> sys.getdefaultencoding()
        'ascii'

    python 3

        >>> sys.getdefaultencoding()
        'utf-8'

- [c for c in sorted([1,2,3], key=lambda c: -c)] - variable `c` will not conflict here

- in py2 variable inside comprehension can change outer variables and also accessible after, in py3 - not

    python 2

        >>> x = 1
        >>> [x for x in range(3)]
        [0, 1, 2]
        >>> x
        2
        # creates new var
        >>> [y for y in range(3)]
        [0, 1, 2]
        >>> y
        2

    python 3

        >>> x = 1
        >>> [x for x in range(3)]
        >>> x
        1
        # no new var
        >>> [y for y in range(3)]
        [0, 1, 2]
        >>> y
        NameError: name 'y' is not defined

- py3 has nonlocal statement. It is used to reference the variable in outer def block (in py2 it is not possible to access such variable)

        def f():
            x = 2  # local for f
            def g():
                nonlocal x  # python3 only
                x = 3  # local for g
            g()
            print(x)
        >>> f()  # python3 only
        3
        >>> f()  # with commented nonlocal
        2


- LEGB rule (local, enclosing, global, builtin) or LNGB (N=nonlocal) - order of variable search in python

- py3 exception variable `as name` is removed after block execution (even if variable was declared before try block)

    python 2

        >>> x = 1
        >>> try:
        ...     1/0
        ... except Exception as x:
        ...     pass
        >>> x
        ZeroDivisionError('integer division or modulo by zero',)

    python 3

        >>> x = 1
        >>> try:
        ...     1/0
        ... except Exception as x:
        ...     pass
        >>> x
        NameError: name 'x' is not defined

- override builtin and undo override

        >>> open = 99
        >>> open
        99
        >>> del open
        >>> open
        <built-in function open>

- py2 fun: `__builtins__.True = False`

- lambda can take default arguments

- nonlocal functionality can be replaced by mutable object or function attribute

        def f():
            x = [1]
            def g():
                print x[0]
                x.append(2)
            g()
            print x
        >>> f()
        1
        [1, 2]

        def f():
            x = 1
            def g():
                print g.x
                g.x = 2
            g.x = x
            g()
            print g.x
        >>> f()
        1
        2

- py3 keyword only arguments

        def f(*args, name):
            print("args", args)
            print("name", name)
        >>> f(1, 2)
        TypeError: f() missing 1 required keyword-only argument: 'name'
        >>> f(1, 2, name=3)
        args (1, 2)
        name 3

        def f(*args, name=3):
            print("args", args)
            print("name", name)
        >>> f(1, 2)
        args (1, 2)
        name 3

- in py3 there is unpack of variables, it returns list. And arguments unpack in function call returns tuple

    python 2 and 3

        def f(a, *b):
            print(b)
        >>> f(1, *[2, 3])
        (2, 3)

    python 3

        >>> a, *b = [1, 2, 3]
        >>> print(b)
        [2, 3]
        >>> a, *b = (1, 2, 3)
        >>> print(b)
        [2, 3]

- add list to the beginning of existing list: L[:0] = [1, 2, 3]

- get and set maximum recursion limit

        >>> sys.getrecursionlimit()  # 1000
        >>> sys.setrecursionlimit(10000)
        >>> help(sys.setrecursionlimit)

- function arguments

        >>> def f(a):
        ...     b = 1
        ... 
        >>> f.__name__
        'f'
        >>> f.__code__.co_varnames
        ('a', 'b')
        >>> f.__code__.co_argcount
        1

- in py3 we can add annotations to function arguments. This information is saved in `func.__annotations__`. Nothing is done automatically with annotations, but we can work with them manually (for example for checking type and range of argument from decorator)

        >>> def func(a: 'spam', b: (1, 10), c: float):
        ...     return a + b + c
        >>> func.__annotations__
        {'b': (1, 10), 'c': <class 'float'>, 'a': 'spam'}

        # default values
        >>> def func(a: 'spam'=4, b: (1, 10)=5, c: float=0.1):
        ...     return a + b + c

- it is impossible to use `=` in lambda, but it is possible to use `setattr`, `__dict__`

- operator module in std lib

        import operator as op
        reduce(op.add, [2, 4, 6])
        # same as
        reduce(lambda x, y: x+y, [2, 4, 6])

- KISS: Keep It Simple [Sir/Stupid]

- comprehension vs map in general (better test on your system)

    `map(lambda x: x ..)` slower than `[x for x ..]`

    `[ord(x) for x ..]` slower than `map(ord for x ..)`

    `map(lambda x: L.append(x+10), range(10))` even slower than `for x in range(10): L.append(x+10)`

- unpacking in lambda differs in py2 and py3

    python 2

        >>> map(lambda (a, b, c): a, [(0,1,2), (3,4,5)])
        [0, 3]

    python 3

        >>> list(map(lambda (a, b, c): a, [(0,1,2), (3,4,5)]))
        SyntaxError: invalid syntax
        >>> list(map(lambda a, b, c: a, [(0,1,2), (3,4,5)]))
        TypeError: <lambda>() missing 2 required positional arguments: 'b' and 'c'
        >>> list(map(lambda row: row[0], [(0,1,2), (3,4,5)]))
        [0, 3]

- many builtin functions accept generators, no additional parenthesis are needed

        >>> "".join(str(x) for x in [1, 2])
        '12'
        >>> sorted(str(x) for x in [1, 2])
        ['1', '2']

    but for args () is needed

        >>> sorted(str(x) for x in [1, 2], reverse=True)
        SyntaxError: Generator expression must be parenthesized if not sole argument
        >>> sorted((str(x) for x in [1, 2]), reverse=True)
        ['2', '1']

- py3: yield from iterator (following functions are the same)

        def f():
            for i in range(5):
                yield i

        def g():
            yield from range(5)

- put last list element to the beginning

        L = L[1:] + L[:1]

- zip for single list

        >>> zip([1,2,3])
        [(1,), (2,), (3,)]

- map and zip are similiar

        map(lambda x,y: (x,y), S1, S2) == zip(S1, S2)

- `python -m script_name` - runs module (module is a .py file), that can be found from current search path. Module can be placed somewhere in site-packages folder, but is run as main (`__name__ = '__main__'`). If script_name is a package (folder with `__init__.py`), then file `__main__.py` will be launched. If no such file, then error. Some modules are smart and accepts arguments from command line, for example timeit: `python -m timeit '"-".join(str(n) for n in range(100))'`

- there is no direct way to use global and local variable with same name simultaneously. We can play with `__main__.my_global_var`

        # OK
        X = 99
        def f():
            print(X)
        >>> f()
        99

        # ERROR
        def f():
            print(X)  # <- error
            X = 99
        >>> f()
        UnboundLocalError: local variable 'X' referenced before assignment

        # global everywhere
        def f():
            global X
            print(X)
            X = 88

        # hack with main
        def f():
            import __main__
            print(__main__.X)
            X = 88

- square root performance

        math.sqrt(x)  # fastest
        x ** .5  # fast
        pow(x, .5)  # slow

- py3.2+ creates folder `__pycache__` for saving bytecode of different python versions there and to reuse them in future. There are no *.pyc files outside this folder now.

- .pyc for main script (`__name__ = '__main__'`) is not created, only for import

- import search order (look at sys.path):

    1. home of program (+ in some versions current dir, from where program is launched, i.e. current dir)
    2. PYTHONPATH
    3. std lib dir
    4. content of any .pth file (if exists)
    5. site-packages dir

- sys.path can be changed at runtime, this will impact all program

- python -O creates a little bit optimized bytecode .pyo instead of .pyc, it ~5% faster. Also this flag removes all asserts from code. And changes value of var `__debug__`

        # main.py
        print __debug__
        assert True == False

        # python main.py
        True
        AssertionError

        # python -O main.py
        False

- in py2 in function we can do `from some_module import *`, but with warning. In py3 - error

        # python 2
        def f():
            from urllib import *
            print('after import')
        >>> f()
        SyntaxWarning: import * only allowed at module level
        after import

        # python 3
        >>> f()
        SyntaxError: import * only allowed at module level

- `reload` doesn't update objects, that are loaded with from: `from x import y`. `y` will not be reloaded after `reload(x)`

- `reload` doesn't update c modules

- py3: in package there is **no** package folder in sys.path. If module in package needs to import another module from the same package, relative import must be used: `from . import smth`. However, if module is launched as main program (`__main__`), then package folder **is** in sys.path.

- py2: `from __future__ import absolute_import` makes import in py2 the same as in py3. It allows to import module string from standard library in following case very easy:

        mypkg
        ├── __init__.py
        ├── main.py  # import string from std here?
        └── string.py

- relative import is forbidden outside the package

        # test.py
        from . import a

        # python 2
        python test.py
        ValueError: Attempted relative import in non-package

        # python 3
        python test.py
        SystemError: Parent module '' not loaded, cannot perform relative import

- cons of relative import:

    - module with relative imports can't be used as script (`__main__`). Solution: use absolute import with package name at the beginning
    - derives from previous point: we can't launch tests, that are executed when running module as main program

- in py3.3+ there are _namespace packages_. They don't have `__init__.py`. Two (or more) namespace packages with same name can be placed in different locations in sys.path. Modules from those packages will be aggregated under same package name. If modules have same name - first found in sys.path will be taken. Namespace package always has lower priority under regular package (with `__init__.py`). When regular package is found - all found namespace packages with that name are discarded, normal package is used instead. Namespace package import process is slow.

        # collect modules in namespace package
        current_dir
        └── mypkg
            └── mymod1.py

        site-packages
        └── mypkg
            └── mymod2.py

        >>> import mypkg.mymod1
        >>> import mypkg.mymod2

        # redefine module in namespace package
        current_dir
        └── mypkg
            └── mymod1.py
            └── mymod2.py

        site-packages
        └── mypkg
            └── mymod2.py

        >>> import mypkg.mymod1
        >>> import mypkg.mymod2  # current_dir.mypkg.mymod2

        # regular package is used
        current_dir
        └── mypkg
            └── mymod1.py

        site-packages
        └── mypkg
            └── mymod2.py

        another-packages
        └── mypkg
            └── mymod1.py

        >>> import sys
        >>> sys.append('another-packages')
        >>> import mypkg.mymod1  # another-packages.mypkg.mymod1
        >>> import mypkg.mymod2
        ImportError: No module named 'mypkg.mymod2'

- In py2 and py3 new-style classes (inherent from object), when operator is applied, corresponding magic methods are searched in class, ignoring instance (`__getattr__`, `__getattribute__` are not invoked). But on direct call of magic method instance is not ignored (`__getattr__`, `__getattribute__` are invoked).

        class A(object):
            def __repr__(self):
                return "class level repr"
            def normal_method(self):
                return "class level normal method"

        def instance_repr():
            return "instance level repr"
        def instance_normal_method():
            return "instance level normal method"

        a = A()
        print(a)  # class level repr
        print(a.normal_method())  # class level normal method

        a.__repr__ = instance_repr
        a.normal_method = instance_normal_method

        print(a)  # class level repr
        print(a.normal_method())  # instance level normal method

        print(a.__repr__())  # instance level repr

- ZODB - object database for python objects, support ACID-compatible transactions (including savepoints)

- slice object:

        L[2:4] == L[slice(2,4)]

- iteration context (for, while, ...) will try

    1. `__iter__`
    2. `__getitem__`

            class Gen(object):
                def __getitem__(self, index):
                    if index > 5:
                        raise StopIteration()
                    return index

            for x in Gen():
                print x,

            # output
            0 1 2 3 4 5

- for calls `__iter__()`. Then calls method `returned_object.__next__()` (in py2 `.next()`), until `StopIteration`. It is possible to use yield `__item__(): yield smth`, then no need to define `__next__`.

- `__call__` is invoked, when parentheses `()` are applied to instance, not to class

        class A(object):
            def __call__(self):
                print("call")

        a = A()  # nothing
        a()  # print call

- `__eq__` = True doesn't mean, that `__ne__` = False

- boolean context:

    - `__bool__` (`__nonzero__` in py2)
    - `__len__`
    - True

- OOP patterns

    - inheritance - "is a"
    - composition - "has a" (container stores other objects)
    - delegation - special case of composition, when only one object is stored. Wrapper implement same interface, but add some intermediate steps.

- class attributes (including methods), that start with double underscores `__`, but don't end with them, have special behaviour. They do not overlap with same named attributes in child classes. In `__dict__` they are stored as `_ClassName__attrname`.

        class A(object):
            __x = 1

            def show_a(self):
                print self.__x

        class B(A):

            def show_b(self):
                print self.__x

        >>> a = A()
        >>> a.show_a()
        1
        >>> b = B()
        >>> b.show_a()
        1
        >>> b.show_b()
        AttributeError: 'B' object has no attribute '_B__x'

        class B(A):
            __x = 2

            def show_b(self):
                print self.__x

        >>> b = B()
        >>> b.show_a()
        1
        >>> b.show_b()
        2

- in py3 in class method we can suppress self argument and use that method only from class (not from instance) - it will behave as static method. But not in py2.

        class A(object):
            def f():
                print("f")

        # python 2
        >>> A.f()
        TypeError: unbound method f() must be called with A instance as first argument (got nothing instead)

        # python 3
        >>> A.f()
        f
        >>> a = A()
        >>> a.f()
        TypeError: f() takes 0 positional arguments but 1 was given

- bound function:

        class A(object):
            def f(self):
                pass

        a = A()
        print(a.f.__self__)  # that is where self is saved

- attribute search in classic (old-style) and new-style classes:

    - classic. DFLR: Depth First, Left to Right
    - new-style. Diamond pattern, L-R, D-F; MRO (more complex, that just LRDF)

    MRO guards class, from which >= 2 other classes are subclassed, from being search twice. So class will be searched only once.

        # python 2 old-style
        class A: attr = 1

        class B(A): pass

        class C(A): attr = 2

        class D(B,C): pass

        >>> x = D()
        >>> print(x.attr)  # x, D, B, A
        1

        # python 2 new-style
        class A(object): attr = 1

        class B(A): pass

        class C(A): attr = 2

        class D(B,C): pass

        >>> x = D()
        >>> print(x.attr)  # x, D, B, C
        2

        # scheme
        A     A
        |     |
        B     C
        \     /
           |
           D
           |
           X

    Check search order in new-style (mro algorithm):

        >>> D.__mro__
        (<class '__main__.D'>, <class '__main__.B'>, <class '__main__.C'>, <class '__main__.A'>, <type 'object'>)
        >>> D.mro()  # same as list(D.__mro__)
        [<class '__main__.D'>, <class '__main__.B'>, <class '__main__.C'>, <class '__main__.A'>, <type 'object'>]

- format() calls method `__format__`. If it is not exist, then TypeError in py2.

    python 2

        >>> print('{0}'.format(object))
        <type 'object'>
        >>> print('{0}'.format(object.__reduce__))
        TypeError: Type method_descriptor doesn't define __format__
        # call __str__ explictly
        >>> print('{0!s}'.format(object.__reduce__))
        <method '__reduce__' of 'object' objects>

    python 3.4

        >>> print('{0}'.format(object.__reduce__))
        <method '__reduce__' of 'object' objects>

    python 2 & 3

        class A(object):
            def __format__(self, *args):
                return "A.__format__"

            def __str__(self):
                return "A.__str__"

        >>> a = A()
        >>> "{0}".format(a)
        'A.__format__'
        >>> print(a)
        A.__str__
        >>> '%s' % a
        'A.__str__'

- `__dict__` doesn't contain "virtual" attributes:

    - new-style properties (`@property`)
    - slots
    - descriptors
    - dynamic attrs computed with tools like `__getattr__`

- MRO - method resolution order

- diamond pattern - special case of 'multi inheritance', when 2 or more class can be child of the same class (object). This pattern is used in python.

- proxy object, returned by `super()`, doesn't work with operators:

    python 3

        class A(list):
            def get_some(self):
                return super()[0]

        >>> a = A([1, 2])
        >>> a.get_some()
        TypeError: 'super' object is not subscriptable

        class A(list):
            def get_some(self):
                return super().__getitem__(0)

        >>> a = A([1,2])
        >>> a.get_some()
        1


    python 2

        class A(list):
            def get_some(self):
                return super(A, self)[0]

        >>> a = A([1,2])
        >>> a.get_some()
        TypeError: 'super' object has no attribute '__getitem__'

        class A(list):
            def get_some(self):
                return super(A, self).__getitem__(0)

        >>> a = A([1,2])
        >>> a.get_some()
        1

- super()

    - super() pros:

        - if superclass need to be changed in runtime, we can't do it without super: `C.__bases__ = (Y, )`
        - calls sequence of inherited methods in multi inheritance class, in MRO order.

            If we'll try to do it without super, we can call method of some class twice.

                class A(object):
                    def __init__(self):
                        print("A")

                class B(A):
                    def __init__(self):
                        print("B")
                        super(B, self).__init__()

                class C(A):
                    def __init__(self):
                        print("C")
                        super(C, self).__init__()

                class D(B, C):
                    pass

                >>> d = D()
                B
                C
                A  # A only once
                >>> B.mro()
                [<class '__main__.B'>, <class '__main__.A'>, <type 'object'>]
                >>> D.mro()
                [<class '__main__.D'>, <class '__main__.B'>, <class '__main__.C'>, <class '__main__.A'>, <type 'object'>]

            Sequence of methods

                class B(object):
                    def __init__(self):
                        print("B")
                        # for B super is C here, by MRO order
                        super(B, self).__init__()

                class C(object):
                    def __init__(self):
                        print("C")
                        # it is ok here to call super().__init__
                        # because object also has __init__
                        super(C, self).__init__()

                class D(B, C):
                    pass

                >>> d = D()
                B
                C

        - super will search attribute in MRO hierarchy. It will search all classes. So, for example hierarchy for super is the following: `A`, `C`. `A` doesn't have attribute, whereas `C` has, then C.method will be used without error.

    - super() cons (or features):

        - when super is used, all methods in sequence must accept same arguments
        - super().m - all classes must have method m and call super().m, except last one, that must not call super.

- inherit method from exact class:

        class A(B, C):
            other = C.other  # not B other

- finally block will be called even if exception was happened in except or else block

- exception - always instance, even if raise ExceptionClass (without `()`). Instance will be created automatically (without arguments):

        raise Exception  # == raise Exception()
        raise  # reraise caught exception

- py2, look for builtin exceptions:

        import exceptions
        help(exceptions)

- the downside of reading bytes from file and further manual decoding: if we'll read by chunks, then some nasty case can happen, when one byte of one symbol will fall in first chunk, and another byte of same symbol - in second chunk. So it is better to use codecs.open in py2.

- When file name is given in unicode, python will automatically decode and encode from/to bytes. When file name is in bytes, then no encoding is happen. Default encoding for file names:

        >>> sys.getfilesystemencoding()
        'utf-8'

- descriptor - class, that implement one of the following methods

    - `__get__`
    - `__set__`
    - `__delete__`

- If descriptor doesn't implement `__set__`, it doesn't mean, that corresponding attribute is read-only. Attribute will be simply rewritten. To avoid it, implement `__set__` with exception.

- decorators can be combined, they will be called from bottom to top:

        @A
        @B
        @C
        def f(): pass

        # same as

        f = A(B(C(f)))

- decorator can accept arguments

        @dec(a, b)
        def f(): pass

        # same as

        f = dec(a, b)(f)

        # implementation:

        def dec(a, b):
            def actual_dec(f):
                return f
            return actual_dec

    So decorator can include **3 levels of callables**:

    - callable to accept decorator args
    - callable to serve as decorator
    - callable to handle calls to the original function

- during class creation, two methods of class type are called:

        type.__new__(type_class, class_name, super_classes, attr_dict)
        type.__init__(class, class_name, super_classes, attr_dict)

        # python 3
        class Eggs: pass

        class Spam(Eggs):
            data = 1
            def method(self, arg): pass

        # same as
        Eggs = type('Eggs', (), ...)  # in () object will be added automatically in python 3

        Spam = type('Spam', (Eggs, ), {'data': 1, 'method': method, '__module__': '__main__'})

- Set metaclass

    **python 2**

        class Spam(object):
            __metaclass__ = Meta

    Inherit from object is not mandatory, but if it is not present, and `__metaclass__`
    is used, then result will be new-style anyway, and in `__bases__` object will be present.
    But better to use object explicitly, as there can be problems, for example with inheritance.

    **python 3**

        class Spam(Eggs, metaclass=Meta):
            pass

    attribute `__metaclass__` is just ignored


- Metaclass can not be a class itself. It just must return class. Function also can be a metaclass:

        def meta_func(class_name, bases, attr_dict):
            return type(class_name, bases, attr_dict)

        # python 2
        class Spam(object):
            __metaclass__ = meta_func

- Regular classes also have method `__new__`. But it doesn't create class, it is invoked at instance creation (takes class as input argument). This method calls `__init__`.

- Magic methods of metaclass and class:

        class Meta(type): pass

    on creation of class Class (`class Class(metaclass=Meta): ...`) following methods are called:

        Meta.__new__
        Meta.__init__

    on creation of instance of class Class (`instance = Class(...)`) following methods are called:

        Meta.__call__
            calls Class.__new__
                calls Class.__init__

    on calling of instance of class Class (`instance()`) following method is called:

        Class.__call__

- It is not mandatory to subclass metaclass from type. We can use simple class with `__new__` method as metaclass. But in that case methods `__init__` and `__call__` will not be called:

        class MySimpleMetaClass(object):
            def __new__(cls, *args, **kwargs):
                new_class = type.__new__(type, *args, **kwargs)
                return new_class

            def __init__(new_class, *args, **kwargs):
                print("__init__ won't be called...")

            def __call__(*args, **kwargs):
                print("__call__ won't be called...")

- Metaclass of some class will be invoked for all subclasses. When `__new__` of metaclass is called for parent class, bases will contain `(<type 'object'>,)`, and for subclass - parent class.

- Metaclass attributes are inherited by class, not by instances of class.

    python 2 (python 3 has some syntax differences)

        class MyMetaClass(type):
            attr = 2

            def __new__(*args, **kwargs):
                return type.__new__(*args, **kwargs)

            def toast(*args, **kwargs):
                print(args, kwargs)

        class A(object):
            __metaclass__ = MyMetaClass

    Metaclass is included in search sequence of class attributes

        >>> A.toast()
        ((<class '__main__.A'>,), {})

    Interesting, that method from metaclass is bound, although is called from class, not from instance. In fact class - is an instance of metaclass:

        >>> A.toast
        <bound method MyMetaClass.toast of <class '__main__.A'>>

    But metaclass is not present in instance attribute search sequence

        >>> a = A()
        >>> a.toast()
        AttributeError: 'A' object has no attribute 'toast'

    If some superclass has attribute with same name, as in metaclass, it has higher priority (no matter how deep superclass is)

        class B(object):
            attr = 1

        class C(B):
            __metaclass__ = MyMetaClass

        >>> C.attr
        1  # MyMetaClass.attr = 2 is ignored

    Instance attributes are searched in its `__dict__`, next in all `__dict__` of `__class__.__mro__`
    Class attributes are searched also in `__class__.__mro__`, it is different class, from instance it will be `__class__.__class__.__mro__`.

        >>> inst = C()
        >>> inst.__class__ -> <class '__main__.C'>
        >>> C.__bases__    -> (<class '__main__.B'>,)
        >>> C.__class__    -> <class '__main__.MyMetaClass'>

    Instance inherit attributes from all superclasses. Class - from superclasses and metaclasses. Metaclasses - from super-metaclasses (and probably from meta-metaclasess).

    Data descriptors (those, that define `__set__`) brings some changes in attribute search order for instances.
    For class instance, data descriptor will have higher priority in search, even if they are declared in superclasess:

        class DataDescriptor(object):
            def __get__(self, instance, owner):
                print("DataDescriptor.__get__")
                return 5
            def __set__(self, instance, value):
                print("DataDescriptor.__set__", value)


        class B(object):
            attr = DataDescriptor()

        class C(B):
            pass

        >>> c = C()
        >>> c.__dict__['attr'] = 88
        >>> c.attr
        DataDescriptor.__get__
        5
        >>> c.attr = 8
        ('DataDescriptor.__set__', 8)

    Descriptor was called, in spite of attribute with same name is present in `c.__dict__`.
    Attribute doesn't hide descriptor of superclass.
    Such behaviour will not happen in case of nondata descriptor:

        class SimpleDescriptor(object):
            def __get__(self, instance, owner):
                print("SimpleDescriptor.__get__")
                return 5

        class B(object):
            attr = SimpleDescriptor()

        class C(B):
            pass

        >>> c = C()
        >>> c.attr
        SimpleDescriptor.__get__
        5
        >>> c.__dict__['attr'] = 88
        >>> c.attr
        88

    Also, for builtin operators that call magic methods implicitly, the search order is special. It ignores `instance.__dict__`, the search goes to `__dict__` of classes from `__mro__`.

- magic methods, that are called implicitly by builtin operators, are searched in metaclasses, ignoring the class (and all its superclasses)

    python 2 (in python 3 syntax differs a little bit)

        class MyMetaClass(type):
            def __new__(*args, **kwargs):
                return type.__new__(*args, **kwargs)
            def __str__(cls):
                return "__str__ from meta"

        class A(object):
            __metaclass__ = MyMetaClass
            def __str__(self):
                return "__str__ from class A"

    Method `MyMetaClass.__str__` will be called, not `A.__str__`

        >>> print A
        __str__ from meta

    And here method `object.__str__` will be called:

        >>> print MyMetaClass
        <class '__main__.MyMetaClass'>

- Author Mark Lutz is a little upset, that python become too complicated nowadays. It have more than one obvious way to do some things:

    - `str.format` and `%`
    - `with` and `try/finally`

    It goes contrary with `import this` Zen.
