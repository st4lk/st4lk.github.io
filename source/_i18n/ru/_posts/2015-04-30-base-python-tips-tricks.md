---
layout: post
title:  "Python tips & tricks"
date:   2015-04-30 18:19:43 +0000
categories: python
redirect_from:
  - /2015/base-python-tips-tricks/
---

[![Python tips & tricks](https://img-fotki.yandex.ru/get/9067/85893628.c68/0_181e3c_92d918ca_M.jpg "Python tips & tricks")]({{ site.baseurl }}{{ page.url }})

Недавно прочитал книгу [Марка Лутца "Learning Python", 5-ое издание](http://shop.oreilly.com/product/0636920028154.do). Привожу список самых интересных фишек (по моему мнению) оттуда, что-то вроде конспекта.

<!--more-->

- генерация set'a:

        {x for x in [1,2]}
        set(x for x in [1,2])
        assert set(x for x in [1,2]) == {x for x in [1,2]}

- генерация dict'а:

        {x:x**2 for x in [1,2]}
        dict((x, x**2) for x in [1,2])
        assert {x:x**2 for x in [1,2]} == dict((x, x**2) for x in [1,2])

- деление целых чисел

    В python 3 деление целых чисел возвращает float

        >>> 1 / 2
        0.5
        >>> - 1 / 2
        -0.5

    В python 2 деление - округление в меньшую сторону, это не truncate

        >>> 1 / 2    # 0.5 floor округление -> 0
        0
        >>> - 1 / 2  # -0.5 floor округление -> -1 (не 0)
        -1

    В python 2 и 3 целочисленное деление

        >>> 1 // 2
        0
        >>> - 1 // 2
        -1
        >>> 13 // 2.0
        6.0

- `is` - проверяет, что переменные указывают на один и тот же адрес, `==` проверяет, что объекты имеют одинаковые значения

- python 3: `[1, 'spam'].sort()` возбуждает исключение (разные типы)

- python 3: dict().keys() возвращает итератор (view объект, зависимый от dict). Это set-like объект, к нему можно применять set операции (union и пр.)

        >>> dict(a=1, b=2).keys()
        dict_keys(['b', 'a'])
        >>> dict(a=1, b=2).keys() | {'c', 'd'}
        {'b', 'd', 'a', 'c'}

- frozenset - immutable set, он является hashable, можно использовать например как ключ в dict

        >>> fz = frozenset([1,2])
        >>> fz.add(3)
        AttributeError: 'frozenset' object has no attribute 'add'
        >>> {fz: 5}
        {frozenset([1, 2]): 5}

- list поддерживает операторы сравнения: ==, <, >, <=, >=. Сравнение аналогично сравнению срок. Для py3 все объекты должны быть одного типа

        >>> [1, 2] == [1, 2]
        True
        >>> [2, 2] > [1, 2]
        True
        >>> [1] > ['sh']  # python2
        False
        >>> [1] > ['sh']  # python3
        TypeError: unorderable types: int() > str()

- сравнение dict'ов

    python 2 and 3

        >>> dict(a=1) == dict(a=1)
        True

    python 2 only

        >>> dict(a=3) > dict(a=2)
        True
        >>> dict(a=3) > dict(a=2, b=1)
        False

- нельзя list + string, list + tuple, однако можно list += string

        >>> L = []
        >>> L + 'spam'
        TypeError: can only concatenate list (not "str") to list

        >>> L = []
        >>> L += 'spam'
        >>> L
        ['s', 'p', 'a', 'm']

- L += a is faster that L = L + a.

- L += [1,2] is in place modification! (не создается новый список)

        >>> L = []
        >>> id(L)
        4368997048
        >>> L += [1,2]
        >>> id(L)
        4368997048
        >>> L = L + [1,2]
        >>> id(L)
        4368996976

- 'spam'[0][0][0] можно до бесконечности, каждый раз будет возвращатся односимвольная строка 's'

- распаковка аргументов в python 3 при присваивании

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

- python 2: True = 0, но не в python 3

    python 2

        >>> True = 0
        >>> True
        0

    python 3

        >>> True = 0
        SyntaxError: can't assign to keyword

- sys.stdout = open('temp.txt', 'w') - все print'ы будут идти в файл temp.txt

- `and`, `or` возвращают объект, а не True/False

- `while` has `else`

- python 3: `...` все равно что `pass`

- reversed works with lists, not generator

        >>> reversed([1,2,3])
        <list_reverseiterator object at 0x10127c550>
        >>> reversed((x for x in [1,2,3]))
        TypeError: argument to reversed() must be a sequence

- zip итерирует до самой маленькой последовательности

        >>> [x for x in zip([1,2,3], [4,5])]
        [(1, 4), (2, 5)]

- python 2: map(None, s1, s2) тоже самое, что zip, но добавялет None для элементов из более длинной последовательности

    python 2

        >>> map(None, [1,2,3], [4,5])
        [(1, 4), (2, 5), (3, None)]
        >>> map(None, [1,2], [4,5,6])
        [(1, 4), (2, 5), (None, 6)]

    python 3

        >>> list(map(None, [1,2,3], [4,5]))
        TypeError: 'NoneType' object is not callable

- map can take more than one iterators (похоже на zip)

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

- sorted возвращает список (не генератор) в py2 и py3

        >>> sorted(x for x in [2,1,3])
        [1, 2, 3]

- *args понимает любой итератор, не обязательно list

- unzip: zip(*zip(a,b))

        >>> zip(*zip([1,2],[3,4]))
        [(1, 2), (3, 4)]

- py3: map возвращает генератор, пройти по нему можно только раз

        >>> m = map(lambda x: x, [1,2,3])
        >>> [x for x in m]
        [1, 2, 3]
        >>> [x for x in m]
        []

- py3: хоть range и генератор (это хитрый генератор), он поддерживает len() и доступ по индексам

        >>> r = range(10)
        >>> r
        range(0, 10)
        >>> len(r)
        10
        >>> r[3]
        3

- generator allows only single scan

- циклические импорты работают! Но только с import, без from

- у try есть else, который вызовится, если exception не случилось

- `with` similar to `finally`

- except (name1, name2) - orders from top to bottom, from left to right

- `except Exception:` vs `except:` - первое не перехватывает системные исключения (KeyboardInterrupt, SystemExit, GeneratorExit например)

- set().remove(x) - удаляет x или KeyError, set().discard(x) - удаляет x или ничего

- py3.3+ accept u"", U"" для обратной совместимости с py2

- default encoding is in sys module sys.getdefaultencoding()

    python 2

        >>> sys.getdefaultencoding()
        'ascii'

    python 3

        >>> sys.getdefaultencoding()
        'utf-8'

- [c for c in sorted([1,2,3], key=lambda c: -c)] - тут переменная `c` конфликтовать не будет

- в py2 переменная внутри comprehension может изменять внешние переменные а также доступна после, в py3 - нет.

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

- py3 имеет инструкцию nonlocal. Используется для ссылки на имя во внешнем def блоке (в py2 к такой переменной нельзя обратиться)

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


- LEGB rule (local, enclosing, global, builtin) или LNGB (N=nonlocal) - порядок поиска переменной в python

- py3 переменная исключения `as name` удаляется после выполнения блока (даже если переменная была объявлена до try)

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

- переопределить builtin и отменить переопределение

        >>> open = 99
        >>> open
        99
        >>> del open
        >>> open
        <built-in function open>

- py2 fun: `__builtins__.True = False`

- lambda может принимать аргументы по умолчанию

- nonlocal можно заменить mutable объектом или аттрибутом функции

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

- py3 есть распаковка при присваивании, она возвращает list, а распаковка при вызове функции возвращает tuple

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

- добавить список в начало существующего: L[:0] = [1, 2, 3]

- посмотреть и задать максимальный уровень рекурсии

        >>> sys.getrecursionlimit()  # 1000
        >>> sys.setrecursionlimit(10000)
        >>> help(sys.setrecursionlimit)

- аргументы функций

        >>> def f(a):
        ...     b = 1
        ... 
        >>> f.__name__
        'f'
        >>> f.__code__.co_varnames
        ('a', 'b')
        >>> f.__code__.co_argcount
        1

- py3 к аргументам функции можно добавить аннотации. Эти данные доступны в `func.__annotations__`. Автоматически ничего с этими аннотациями не происходит, но с ними можно работать вручную по ситуации (например, для проверки типа или диапазона с помощью своего декоратора)

        >>> def func(a: 'spam', b: (1, 10), c: float):
        ...     return a + b + c
        >>> func.__annotations__
        {'b': (1, 10), 'c': <class 'float'>, 'a': 'spam'}

        # default values
        >>> def func(a: 'spam'=4, b: (1, 10)=5, c: float=0.1):
        ...     return a + b + c

- внутри lambda нельзя присвоить, но можно `setattr`, `__dict__`

- operator module in std lib

        import operator as op
        reduce(op.add, [2, 4, 6])
        # same as
        reduce(lambda x, y: x+y, [2, 4, 6])

- KISS: Keep It Simple [Sir/Stupid]

- comprehension vs map в общем случае (лучше проверить на вашей системе)


    `map(lambda x: x ..)` slower than `[x for x ..]`

    `[ord(x) for x ..]` slower than `map(ord for x ..)`

    `map(lambda x: L.append(x+10), range(10))` even slower than `for x in range(10): L.append(x+10)`

- распаковка в lambda отличатся для py2 и py3

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

- многие встроенные функции могут принимать генераторы, тогда не нужны дополнительные скобки

        >>> "".join(str(x) for x in [1, 2])
        '12'
        >>> sorted(str(x) for x in [1, 2])
        ['1', '2']

    but for args () is needed

        >>> sorted(str(x) for x in [1, 2], reverse=True)
        SyntaxError: Generator expression must be parenthesized if not sole argument
        >>> sorted((str(x) for x in [1, 2]), reverse=True)
        ['2', '1']

- py3: yield from iterator (приведенные ниже функции идентичны)

        def f():
            for i in range(5):
                yield i

        def g():
            yield from range(5)

- поместить первый элемент в конец списка

        L = L[1:] + L[:1]

- zip одного списка

        >>> zip([1,2,3])
        [(1,), (2,), (3,)]

- map и zip похожи

        map(lambda x,y: (x,y), S1, S2) == zip(S1, S2)

- `python -m script_name` - запускает модуль (модуль - это файл .py, т.е. считай скрипт), который ищется в текущих путях поиска. Модуль может лежать где-нибудь в site-packages, а запустится от main (`__name__ == '__main__'`). Если это package (директория с `__init__.py`), то запустится файл `__main__.py`. Если такого нет, то ошибка. Некоторые модули умные и берут аргументы из командной строки, например timeit: `python -m timeit '"-".join(str(n) for n in range(100))'`

- прямой возможности использовать одноименную переменную в одной функции: и глобальную и локальную нет. Можно только играть c `__main__.my_global_var`

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

- скорость вычисления корня числа

        math.sqrt(x)  # fastest
        x ** .5  # fast
        pow(x, .5)  # slow

- py3.2+ создает папку `__pycache__`, чтобы сохранять разные байткоды для разных версий python'а и не пересоздавать их впоследствии. В корне уже нет *.pyc.

- .pyc для вызывающегося скрипта (`__name__ = '__main__'`) не создается, только для import

- порядок поиска при импорте (можно посмотреть в sys.path):

    1. home of program (+ in some versions current dir, from where program is launched, i.e. current dir)
    2. PYTHONPATH
    3. std lib dir
    4. content of any .pth file (if exists)
    5. site-packages dir

- sys.path можно изменять в runtime, это затронет всю программу

- python -O создает слегка опимизированный байткод .pyo вместо .pyc, он на ~5% быстрее. Также этот флаг убирает все assert'ы из кода. А так же влияет на переменную `__debug__`

        # main.py
        print __debug__
        assert True == False

        # python main.py
        True
        AssertionError

        # python -O main.py
        False

- в py2 в функции можно сделать `from some_module import *`, но будет warning. В py3 - error

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

- reload не обновляет объекты, загруженные с помощью from: `from x import y`. `y` не обновится после `reload(x)`

- reload не обновляет c-шные модули

- py3: в package текущей папки пакета нету в sys.path. Если модуль в пакете хочет импортировать другой модуль из этого же пакета, надо использовать относительный импорт: `from . import smth`. Однако, если модуль запускается как `__main__`, то есть.

- py2: `from __future__ import absolute_import` делает поведение import в py2 таким же, как в py3. Это позволит импортировать модуль string из стандартной библиотеки в данном случае довольно просто:

        mypkg
        ├── __init__.py
        ├── main.py  # import string from std here?
        └── string.py

- относительный импорт запрещен вне пакета:

        # test.py
        from . import a

        # python 2
        python test.py
        ValueError: Attempted relative import in non-package

        # python 3
        python test.py
        SystemError: Parent module '' not loaded, cannot perform relative import

- минусы относительного импорта:

    - модуль, в котором используются относительные импорты нельзя использовать как скрипт (`__main__`). Решение: использовать в модуле абсолютный импорт с именем пакета в начале.
    - как следствие предыдущего пункта, нельзя запустить тесты, которые запускаются при запуске модуля как скрипта

- в py3.3+ есть namespace packages. Это такие пакеты, в которых нет `__init__.py`. Два (или более) namespace package с одним и тем же именем могут лежать в разных директориях из sys.path. При этом модули пакетов собираются под этим именем. Если у модулей одинаковые имена - берется тот, который найден раньше в порядке sys.path. namespace пакет всегда имеет меньший приоритет над обычным пакетом (с `__init__.py`). Как только где-то найден обычный пакет - используется он, все найденные namespace packages отметаются. namespace пакеты медленнее импортятся, чем обычные.

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

- В py3 и в py2 new style classes (отнаследованные от object) магические методы при выполнении оператора ищутся в классе, минуя инстанс (`__getattr__`, `__getattribute__` не вызываются). Но если явно вызвать магический метод - то вызывается от инстанса (`__getattr__`, `__getattribute__` вызываются).

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

- ZODB - объектно ориентированная база данных для python объектов, поддерживает ACID транзакции (включая savepoints)

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

- for вызывает `__iter__()`. Потом к полученному объекту вызывает `__next__()` (в py2 `.next()`), пока не получит `StopIteration`. В классе можно использовать `__iter__(): yield ...`, тогда не надо реализовать `__next__`

- `__call__` вызывается, когда скобки `()` применяются к инстансу, а не к классу

        class A(object):
            def __call__(self):
                print("call")

        a = A()  # nothing
        a()  # print call

- `__eq__` = True не подразумевает, что `__ne__` = False

- boolean context:

    - `__bool__` (`__nonzero__` in py2)
    - `__len__`
    - True

- паттерны ООП

    - inheritance - "is a"
    - composition - "has a" (контейнер хранит другие объекты)
    - delegation - вид composition, когда хранится только один объект. Wrapper сохраняет основной интерфейс, добавляя какие-то шаги.

- аттрибуты и методы класса, которые начинаются с двух подчеркиваний `__`, но не заканчиваются ими, имеют особое поведение. Они не пересекаются с одноименными аттрибутами и методами унаследованного класса. В `__dict__` они попадают под именем `_ClassName__attrname`.

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

- в py3 можно в методе класса не указывать аргумент self, и использовать его только от имени класса (не инстанса) - он будет работать как static method. В py2 так нельзя.

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
        print(a.f.__self__)  # вот где хранится self

- поиск аттрибутов в classic (old-style) классах и new-style классах:

    - classic. DFLR: Depth First, Left to Right
    - new-style. Diamond pattern, L-R, D-F; MRO (хитрее, чем просто LRDF)

    MRO исключает класс, от которого унаследованны >= 2 других класса, от поиска аттрибуты дважды. Т.е. класс пападает в поиск только 1 раз.

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

    Посмотреть порядок поиска в new-style (по алгоритму mro):

        >>> D.__mro__
        (<class '__main__.D'>, <class '__main__.B'>, <class '__main__.C'>, <class '__main__.A'>, <type 'object'>)
        >>> D.mro()  # все равно что list(D.__mro__)
        [<class '__main__.D'>, <class '__main__.B'>, <class '__main__.C'>, <class '__main__.A'>, <type 'object'>]

- format() конструкция вызывает метод `__format__`. Если его нет, то в py2 - TypeError.

    python 2

        >>> print('{0}'.format(object))
        <type 'object'>
        >>> print('{0}'.format(object.__reduce__))
        TypeError: Type method_descriptor doesn't define __format__
        # явно вызовим __str__
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

- В `__dict__` не попадают "виртуальные" аттрибуты:

    - new-style properties (`@property`)
    - slots
    - descriptors
    - dynamic attrs computed with tools like `__getattr__`

- MRO - method resolution order

- diamond pattern - разновидность 'multi inheritance', когда 2 или более класса могут быть потомками одного и того же класса (object). Этот паттерн используется в python.

- прокси объект, который возвращает `super()`, не работает с операторами:

        # python 3
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


        # python 2
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

    - Плюсы super():

        - если superclass нужно изменить в runtime, без super не получится: `C.__bases__ = (Y, )`
        - когда нужно вызвать цепочки унаследованных методов в multi inheritance классе, в порядке MRO.

            Если попытаться вызвать без super, то можем вызвать метод какого-то класса дважды.

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
                A
                >>> B.mro()
                [<class '__main__.B'>, <class '__main__.A'>, <type 'object'>]
                >>> D.mro()
                [<class '__main__.D'>, <class '__main__.B'>, <class '__main__.C'>, <class '__main__.A'>, <type 'object'>]

            Вызов цепочки методов

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

        - super будет искать метод в иерархии MRO. Он будет искать пока не найдет или пока не упрется. Т.е. допустим иерархия для super: A, С, и в A нет метода, а в C есть, то вызовится C.method без ошибки

    - минусы (или особенности) super():

        - при использовании super все методы в цепочке должны принимать одинаковые аргументы
        - super().m - все классы должны иметь метод m и вызывать super().m, кроме последнего, который вызывать super не должен

- унаследовать метод от конкретного класса:

        class A(B, C):
            other = C.other  # not B other

- finally вызовится даже если исключение случается в except блоке или else блоке

- исключение - всегда instance, даже если raise ExceptionClass (без `()`), автоматически (без аргументов) создается instance:

        raise Exception  # == raise Exception()
        raise  # возбуждается перехваченное исключение

- py2, посмотреть исключения builtin:

        import exceptions
        help(exceptions)

- минус чтения байтов из файла с последующим ручным decode в том, что если мы будем читать по кускам, то может быть сложный случай, когда один байт одного символа попадает в один кусок, а другой - в другой. Поэтому в py2 лучше использовать codecs.

- Когда имя файла даем в unicode, python автоматически декодит и кодит в байты. Когда имя файла - байты, то не кодит нечего. encoding для имен файлов (дефолтный):

        >>> sys.getfilesystemencoding()
        'utf-8'

- дескриптор - это класс, который реализует хотя бы один из методов

    - `__get__`
    - `__set__`
    - `__delete__`

- Если в дескрипторе не реализовать `__set__`, то это еще не значит, что соответствующий аттрибут будет read-only. Аттрибут просто перезатрется. Надо делать `__set__` с исключением.

- декоратры можно совмещать, тогда они будут применяться в порядке снизу вверх:

        @A
        @B
        @C
        def f(): pass

        # все равно что

        f = A(B(C(f)))

- декоратор может принимать аргументы. Реализовать можно через вложенные функции

        @dec(a, b)
        def f(): pass

        # все равно что

        f = dec(a, b)(f)

        # реализация:

        def dec(a, b):
            def actual_dec(f):
                return f
            return actual_dec

    Т.е. декоратор может включать **3 уровня callables**:

    - callable to accept decorator args
    - callable to serve as decorator
    - callable to handle calls to the original function

- при создании класса вызываются два метода класса type:

        type.__new__(type_class, class_name, super_classes, attr_dict)
        type.__init__(class, class_name, super_classes, attr_dict)

        # python 3
        class Eggs: pass

        class Spam(Eggs):
            data = 1
            def method(self, arg): pass

        # все равно, что
        Eggs = type('Eggs', (), ...)  # в () object добавится автоматически

        Spam = type('Spam', (Eggs, ), {'data': 1, 'method': method, '__module__': '__main__'})

- Задать метакласс для класса

    **python 2**

        class Spam(object):
            __metaclass__ = Meta

    Наследовать от object не обязательно, но если его нет, а `__metaclass__`
    есть, то результат все равно будет new-style, и в `__bases__` будет object.
    Но лучше явно указать object, т.к. могут быть проблемы, например с наследованием.

    **python 3**

        class Spam(Eggs, metaclass=Meta):
            pass

    аттрибут `__metaclass__` просто игнорируется


- Метакласс сам не обязательно должен быть классом. Просто его вызов должен возвращать класс. Это может быть и функция:

        def meta_func(class_name, bases, attr_dict):
            return type(class_name, bases, attr_dict)

        # python 2
        class Spam(object):
            __metaclass__ = meta_func

- У обычных классов тоже есть метод `__new__`. Но он не создает класс, он вызывается при создании инстанса класса (получает готовый класс в качестве аргумента). Он же и вызывает `__init__`.

- Магические методы метакласса и класса:

        class Meta(type): pass

    при создании класса Class (`class Class(metaclass=Meta): ...`) вызываются методы

        Meta.__new__
        Meta.__init__

    при создании инстанса класса Class (`instance = Class(...)`) вызываются методы (внешний вызывает вложенный)

        Meta.__call__
            calls Class.__new__
                calls Class.__init__

    при вызове инстанса класса Class (`instance()`) вызывается метод

        Class.__call__

- Метакласс можно не наследовать от type, а определить метод `__new__`. Но тогда методы `__init__`, `__call__` нашего метакласса не будут вызываться:

        class MySimpleMetaClass(object):
            def __new__(cls, *args, **kwargs):
                new_class = type.__new__(type, *args, **kwargs)
                return new_class

            def __init__(new_class, *args, **kwargs):
                print("__init__ won't be called...")

            def __call__(*args, **kwargs):
                print("__call__ won't be called...")

- Метакласс класса вызывается и для всех потомков класса. Когда `__new__` метакласса вызывается для родительского класса, в bases будет `(<type 'object'>,)`, а для дочернего класса - класс родителя.

- Аттрибуты метакласса наследуются классом, но не инстансами класса.

    python 2 (в python 3 небольшие отличия в синтаксисе)

        class MyMetaClass(type):
            attr = 2

            def __new__(*args, **kwargs):
                return type.__new__(*args, **kwargs)

            def toast(*args, **kwargs):
                print(args, kwargs)

        class A(object):
            __metaclass__ = MyMetaClass

    Метакласс входит в цепочку поиска аттрибутов класса

        >>> A.toast()
        ((<class '__main__.A'>,), {})

    Интересно, что метод от метакласса - bound, хотя вызывается от класса, не от инстанса. На самом деле класс - это инстанс метакласса:

        >>> A.toast
        <bound method MyMetaClass.toast of <class '__main__.A'>>

    Но метакласс не входит в цепочку поиска аттрибутов инстанса класса

        >>> a = A()
        >>> a.toast()
        AttributeError: 'A' object has no attribute 'toast'

    Если в каком-нибудь super классе объявлен аттрибут с тем же именем, что и в метаклассе, то он имеет преимущество (не важно насколько глубоко super)

        class B(object):
            attr = 1

        class C(B):
            __metaclass__ = MyMetaClass

        >>> C.attr
        1  # MyMetaClass.attr = 2 is ignored

    Аттрибуты инстанса ищутся в его `__dict__`, дальше в `__dict__`'ах `__class__.__mro__`.
    Аттрибуты класса ищутся еще и в `__class__.__mro__`, это другой класс, со стороны инстанса это будет `__class__.__class__.__mro__`.

        >>> inst = C()
        >>> inst.__class__ -> <class '__main__.C'>
        >>> C.__bases__    -> (<class '__main__.B'>,)
        >>> C.__class__    -> <class '__main__.MyMetaClass'>

    Инстансы наследуют аттрибуты от всех суперклассов. Классы - от суперклассов и метаклассов. Метаклассы - от супер-метаклассов (и вероятно от мета-метаклассов).

    Data descriptor'ы (те, которые определяют `__set__`) вносят небольшие поправки в порядок поиска аттрибутов для инстанса.
    Для инстанса, data descriptor будут иметь преимущество в поиске, даже если они объявлены в супер классах:

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

    Вызвался дескриптор, несмотря на то, что мы задали аттрибут с тем же именем в `c.__dict__`.
    Аттрибут не затер дескриптор суперкласса, сработал дескриптор.
    Такого поведения не будет с обычным дескриптором (nondata):

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

    Так же, для builtin операторов, которые вызывают магические методы, поиск особый. Он минует `instance.__dict__`, сразу идет поиск в `__dict__` классов из `__mro__`.

- магические методы, которые вызываются неявно путем использования builtin операторов для классов ищутся в метаклассе, минуя сами классы (сам класс и всего его суперклассы):

    python 2 (в python 3 небольшие отличия в синтаксисе)

        class MyMetaClass(type):
            def __new__(*args, **kwargs):
                return type.__new__(*args, **kwargs)
            def __str__(cls):
                return "__str__ from meta"

        class A(object):
            __metaclass__ = MyMetaClass
            def __str__(self):
                return "__str__ from class A"

    Вызывается метод `__str__` метакласса, а не класса:

        >>> print A
        __str__ from meta

    А тут вызывается метод `__str__` от object:

        >>> print MyMetaClass
        <class '__main__.MyMetaClass'>

- Автор Марк Лутц немного беспокоится, что python становится слишком сложным и обрастает дублирующим функционалом, например:

    - `str.format` и `%`
    - `with` и `try/finally`

    Это противоречит `import this`
