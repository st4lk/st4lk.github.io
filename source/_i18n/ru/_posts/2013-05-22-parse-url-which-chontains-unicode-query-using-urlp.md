---
layout: post
title:  "Парсинг url'а, содержащего unicode параметры, используя urlparse.parse_qs"
date:   2013-05-22 18:19:43 +0000
categories: django python unicode
redirect_from:
  - /2013/parse-url-which-chontains-unicode-query-using-urlp/
  - /blog/2013/05/22/parse-url-which-chontains-unicode-query-using-urlp.html
---

Задача: получить словарь параметров URL'a. Например, имеем адрес:

```
http://example.com/?key=value&a=b
```

и нужно получить такой словарь:

```python
{'key': ['value'], 'a': ['b']}
```

Тут значения являются списками, т.к. у одного ключа может быть несколько значений:

```python
In: http://example.com/?key=value&a=b&a=c
Out: {'key': ['value'], 'a': ['b', 'c']}
```

<!--more-->

В python'е для этих целей есть функция `urlparse.parse_qs`, которая делает следующее:

```python
>>> import urlparse
>>> query = "key=value&a=b"
>>> urlparse.parse_qs(query)
{'a': ['b'], 'key': ['value']}
```

Т.е. на вход функции `parse_qs` нужно давать сами параметры, без "http://exapmle.com/?". Для отделения параметров от остального адреса, можно воспользоваться функцией `urlparse.urlparse`:

```python
>>> import urlparse
>>> url = "http://example.com/?key=value&a=b"
>>> query = urlparse.urlparse(url).query
>>> query
'key=value&a=b'
>>> params = urlparse.parse_qs(query)
>>> params
{'a': ['b'], 'key': ['value']}
```

Попробуем восстановить исходные параметры url'а. Воспользуемся функцией urllib.urlencode:

```python
>>> import urllib
>>> urllib.urlencode(params, doseq=True)
'a=b&key=value'
```

Порядок параметров значения не имеет, так что все ок.

#### URL с unicode параметром

По [RFC3986](http://tools.ietf.org/html/rfc3986), URL может содержать только ограниченный набор символов из набора [US-ASCII](http://sliderule.mraiow.com/w/images/7/73/ASCII.pdf), состоящий из цифр, букв и нескольких графических символов. Причем некоторые графические символы являются зарезервированными `(":", "/", "?", "#", "[", "]", "@", "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "=")`. Если в URL нужно передать непечатные или зарезервированные символы (например как значение параметра), то их нужно кодировать по правилам [Percent-Encoding](http://tools.ietf.org/html/rfc3986#section-2.1): %HH, где HH - это шестнадцатеричный код.

Предположим нужно передать u"значение". В python'е строка `u"значение"` содержит unicode коды, нам нужно получить байты. Для этого закодируем строку например кодировкой utf8:

```python
>>> value = u'значение'
>>> value_utf8 = value.encode('utf8')
>>> value_utf8
'\xd0\xb7\xd0\xbd\xd0\xb0\xd1\x87\xd0\xb5\xd0\xbd\xd0\xb8\xd0\xb5'
```

Теперь уже надо закодировать эти байты, используя Percent-Encoding (%HH), для передачи в url:

```python
>>> value_url = urllib.quote(value_utf8)
>>> value_url
'%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%D0%BD%D0%B8%D0%B5'
```

Построим полный адрес:

```python
>>> url = "http://example.com/?key=%s&a=b" % value_url
>>> url
'http://example.com/?key=%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%D0%BD%D0%B8%D0%B5&a=b'
```

И опять попробуем получить словарь параметров:

```python
>>> query = urlparse.urlparse(url).query
>>> query
'key=%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%D0%BD%D0%B8%D0%B5&a=b'
>>> params = urlparse.parse_qs(query)
>>> params
{'a': ['b'], 'key': ['\xd0\xb7\xd0\xbd\xd0\xb0\xd1\x87\xd0\xb5\xd0\xbd\xd0\xb8\xd0\xb5']}
```

Видим, что parse_qs раскодировал значение из кодировки Percent-Encoding и вернул нам байты. Можно теперь получить unicode, ведь мы помним, что кодировали строку с помощью utf8:

```python
>>> params['key'][0].decode('utf8')
u'\u0437\u043d\u0430\u0447\u0435\u043d\u0438\u0435'
>>> print params['key'][0].decode('utf8')
значение
```

Ок. Восстановим исходные параметры из полученного словаря:

```python
>>> urllib.urlencode(params, doseq=True)
'a=b&key=%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%D0%BD%D0%B8%D0%B5'
```

Получили те же параметры, которые и задавали вначале.

**Проделаем тоже самое для URL, которая возвращается в django при вызове `request.get_full_path()`**.
request.get_full_path() почему-то возвращает не строку (str), а unicode (пробовал на django 1.4, 1.5):

```python
>>> request.get_full_path()
u'/?key=%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%D0%BD%D0%B8%D0%B5&a=b'
```

Повторим те же шаги c этой url:

```python
>>> url = request.get_full_path()
>>> query = urlparse.urlparse(url).query
>>> query
u'key=%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%D0%BD%D0%B8%D0%B5&a=b'
>>> params = urlparse.parse_qs(query)
>>> params
{u'a': [u'b'], u'key': [u'\xd0\xb7\xd0\xbd\xd0\xb0\xd1\x87\xd0\xb5\xd0\xbd\xd0\xb8\xd0\xb5']}
```

Интересно, что значение для u'key' представляет из себя unicode строку, которая содержит байты! Конечно же, раскодировать ее уже не получится:

```python
>>> params['key'][0].decode('utf8')
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "C:\Python27\lib\encodings\utf_8.py", line 16, in decode
    return codecs.utf_8_decode(input, errors, True)
UnicodeEncodeError: 'ascii' codec can't encode characters in position 0-15: ordinal not in range(128)
```

То же самое получим и с urlencode:

```python
>>> urllib.urlencode(params, doseq=True)
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "C:\Python27\lib\urllib.py", line 1337, in urlencode
    l.append(k + '=' + quote_plus(str(elt)))
UnicodeEncodeError: 'ascii' codec can't encode characters in position 0-15: ordinal not in range(128)
```

Тут для меня были две неожиданности:
- django вернул url как unicode (зачем? почему не обычная строка `str`, ведь в url'е не могут быть не-ASCII символы)
- parse_qs вернул строку unicode, которая содержит байты.

Решение простое, на вход parse_qs нужно давать только строку `str`:

```python
>>> url = request.get_full_path()
>>> url = url.encode('ascii')
>>> url
'/?key=%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%D0%BD%D0%B8%D0%B5&a=b'
```

Либо так, что тоже самое:

```python
>>> url = request.get_full_path()
>>> url = str(url)
>>> url
'/?key=%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%D0%BD%D0%B8%D0%B5&a=b'
```

Ссылки:
- Вопрос на эту тему на [stackoverflow](http://stackoverflow.com/questions/16614695/python-urlparse-parse-qs-unicode-url)
- Отличная презентация про кодировки строк на python'e: [http://nedbatchelder.com/text/unipain.html](http://nedbatchelder.com/text/unipain.html)
