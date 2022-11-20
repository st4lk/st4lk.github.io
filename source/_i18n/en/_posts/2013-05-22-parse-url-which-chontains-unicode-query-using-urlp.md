---
layout: post
title:  "Parse url which contains unicode query, using urlparse.parse_qs"
date:   2013-05-22 18:19:43 +0000
categories: django python unicode
redirect_from:
  - /2013/parse-url-which-chontains-unicode-query-using-urlp/
---

Task: get dictionary of URL GET query. For example, we have following url:

```
http://example.com/?key=value&a=b
```

it is needed to get a dict:

```python
{'key': ['value'], 'a': ['b']}
```

Values are lists, because one key may have several values:

```python
In: http://example.com/?key=value&a=b&a=c
Out: {'key': ['value'], 'a': ['b', 'c']}
```

<!--more-->

In python there is a function urlparse.parse_qs for that purpose:

```python
>>> import urlparse
>>> query = "key=value&a=b"
>>> urlparse.parse_qs(query)
{'a': ['b'], 'key': ['value']}
```

So, on input `parse_qs` receives query, without "http://exapmle.com/?". To get only query we can use `urlparse.urlparse`:

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

Lets restore original url, using urllib.urlencode:

```python
>>> import urllib
>>> urllib.urlencode(params, doseq=True)
'a=b&key=value'
```

The order of parameters doesn't matter, so it's ok.

#### URL with unicode parameter

According to [RFC3986](http://tools.ietf.org/html/rfc3986), URL can contain only limited set of characters consisting of digits, letters, and a few graphic symbols from [US-ASCII](http://sliderule.mraiow.com/w/images/7/73/ASCII.pdf) set. And some of characters are reserved `(":", "/", "?", "#", "[", "]", "@", "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "=")`. If it is needed to send nonprintable or reserved characters in URL (for example as query param value), they must be [Percent-Encoded](http://tools.ietf.org/html/rfc3986#section-2.1): %HH, where HH is hexadecimal digits.

Suppose we need to send u"значение". In python string `u"значение"` contains unicode code points and we need to get bytes, to be able to percent-encode them. So first lets encode the unicode string using, for example, utf8 encoding:

```python
>>> value = u'значение'
>>> value_utf8 = value.encode('utf8')
>>> value_utf8
'\xd0\xb7\xd0\xbd\xd0\xb0\xd1\x87\xd0\xb5\xd0\xbd\xd0\xb8\xd0\xb5'
```

Now encode those bytes, using Percent-Encoding (%HH) to be able to include in url:

```python
>>> value_url = urllib.quote(value_utf8)
>>> value_url
'%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%D0%BD%D0%B8%D0%B5'
```

Full URL:

```python
>>> url = "http://example.com/?key=%s&a=b" % value_url
>>> url
'http://example.com/?key=%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%D0%BD%D0%B8%D0%B5&a=b'
```

Again, lets get the query dict:

```python
>>> query = urlparse.urlparse(url).query
>>> query
'key=%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%D0%BD%D0%B8%D0%B5&a=b'
>>> params = urlparse.parse_qs(query)
>>> params
{'a': ['b'], 'key': ['\xd0\xb7\xd0\xbd\xd0\xb0\xd1\x87\xd0\xb5\xd0\xbd\xd0\xb8\xd0\xb5']}
```

As we can see, parse_qs decoded value from Percent-Encoding and returned bytes. Now we can get unicode, as we remember, that encoding was utf8:

```python
>>> params['key'][0].decode('utf8')
u'\u0437\u043d\u0430\u0447\u0435\u043d\u0438\u0435'
>>> print params['key'][0].decode('utf8')
значение
```

Ok. Restore original query from the dict:

```python
>>> urllib.urlencode(params, doseq=True)
'a=b&key=%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%D0%BD%D0%B8%D0%B5'
```

We've got same parameters as it was in original url.

**Same steps with URL, that was returned from django's `request.get_full_path()`**.
For some reason, request.get_full_path() returns not the `str` string, but `unicode` (tried on django 1.4, 1.5):

```python
>>> request.get_full_path()
u'/?key=%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%D0%BD%D0%B8%D0%B5&a=b'
```

Repeat same steps with this URL:

```python
>>> url = request.get_full_path()
>>> query = urlparse.urlparse(url).query
>>> query
u'key=%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%D0%BD%D0%B8%D0%B5&a=b'
>>> params = urlparse.parse_qs(query)
>>> params
{u'a': [u'b'], u'key': [u'\xd0\xb7\xd0\xbd\xd0\xb0\xd1\x87\xd0\xb5\xd0\xbd\xd0\xb8\xd0\xb5']}
```

Interesting, that value for u'key' is unicode string, that contains bytes! Of course, decoding of that string will fail:

```python
>>> params['key'][0].decode('utf8')
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "C:\Python27\lib\encodings\utf_8.py", line 16, in decode
    return codecs.utf_8_decode(input, errors, True)
UnicodeEncodeError: 'ascii' codec can't encode characters in position 0-15: ordinal not in range(128)
```

Same error using urlencode:

```python
>>> urllib.urlencode(params, doseq=True)
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "C:\Python27\lib\urllib.py", line 1337, in urlencode
    l.append(k + '=' + quote_plus(str(elt)))
UnicodeEncodeError: 'ascii' codec can't encode characters in position 0-15: ordinal not in range(128)
```

For me there are two surprises:
- django returned url as unicode (what for? why not just str as url can contain only ascii characters)
- parse_qs returned unicode string, that contains bytes.

Solution is simple, just always give `str` to parse_qs:

```python
>>> url = request.get_full_path()
>>> url = url.encode('ascii')
>>> url
'/?key=%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%D0%BD%D0%B8%D0%B5&a=b'
```

Or, which is the same:

```python
>>> url = request.get_full_path()
>>> url = str(url)
>>> url
'/?key=%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%D0%BD%D0%B8%D0%B5&a=b'
```

Links:

- Question about this problem on [stackoverflow](http://stackoverflow.com/questions/16614695/python-urlparse-parse-qs-unicode-url)
- Great presentation about python strings and encoding: [http://nedbatchelder.com/text/unipain.html](http://nedbatchelder.com/text/unipain.html)
