---
layout: post
title:  "Форматирование unicode строк"
date:   2013-06-20 18:19:43 +0000
categories: python unicode
redirect_from:
  - /2013/unicode-string-formatting/
  - /blog/2013/06/20/unicode-string-formatting.html
---

Вы знали, что если одно из значений строкового выражения с оператором `%` - unicode, то вся результирующая строка будет тоже unicode?

```python
>>> "Hello, %s" % u"Alex"
u'Hello, Alex'
>>> "Hello, %s" % u"Алексей"
u'Hello, \u0410\u043b\u0435\u043a\u0441\u0435\u0439'
```

<!--more-->

Я привык пользоваться методом `.format` для форматирования строк и его поведение мне больше нравится: тип исходной строки всегда сохраняется, а если в качестве параметра даются не ascii символы, то возбуждается исключение `UnicodeEncodeError`.

```python
>>> "Hello, {0}".format(u"Alex")
'Hello, Alex'
>>> "Hello, {0}".format(u"Алексей")
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
UnicodeEncodeError: 'ascii' codec can't encode characters in position 0-6: ordinal not in range(128)
>>> u"Hello, {0}".format(u"Алексей")
u'Hello, \u0410\u043b\u0435\u043a\u0441\u0435\u0439'
```

А большая ли разница, что вернется - обычная строка или строка unicode? Иногда да, например в случае с [urlparse.parse_qs](http://www.lexev.org/2013/parse-url-which-chontains-unicode-query-using-urlp/), тип строки имеет значение.

Т.е. нужно иметь в виду, что код вида:

```python
>>> "Hello, %s" % value
```

вполне может вернуть unicode строку.

Ссылки:
- [Документация %](http://docs.python.org/2/library/stdtypes.html#string-formatting)
- [Документация .format](http://docs.python.org/2/library/string.html#format-string-syntax)
