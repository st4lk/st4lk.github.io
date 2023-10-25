---
layout: post
title:  "Unicode string formatting"
date:   2013-06-20 18:19:43 +0000
categories: python unicode
redirect_from:
  - /2013/unicode-string-formatting/
  - /blog/2013/06/20/unicode-string-formatting.html
---

Did you know, if one of values in string formatting expression with `%` operator is unicode, then result string will also be unicode?

```python
>>> "Hello, %s" % u"Alex"
u'Hello, Alex'
>>> "Hello, %s" % u"Алексей"
u'Hello, \u0410\u043b\u0435\u043a\u0441\u0435\u0439'
```

<!--more-->

I used to work with `.format` string method and its behavior is more attractive to me: type of source string is saved and if some parameter contains non-ascii symbols, `UnicodeEncodeError` exception is raised.

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

Is it a big deal, what string type is returned? Well, sometimes yes. For example when working with [urlparse.parse_qs](http://www.lexev.org/en/2013/parse-url-which-chontains-unicode-query-using-urlp/), type of string make sense.

So it is better to keep in mind, that code like:

```python
>>> "Hello, %s" % value
```

can return a unicode string.

Some links:
- [% documentation](http://docs.python.org/2/library/stdtypes.html#string-formatting)
- [.format documentation](http://docs.python.org/2/library/string.html#format-string-syntax)
