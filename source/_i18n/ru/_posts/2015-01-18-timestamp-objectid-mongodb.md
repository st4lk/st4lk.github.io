---
layout: post
title:  "Timestamp и ObjectId в mongoDB"
date:   2015-01-18 18:19:43 +0000
categories: database mongodb
redirect_from:
  - /2015/timestamp-objectid-mongodb/
---

[![Timestamp и ObjectId в mongoDB](https://img-fotki.yandex.ru/get/17859/85893628.c67/0_16f717_c4a5da7b_orig.png "Timestamp и ObjectId в mongoDB")]({{ site.baseurl }}{{ page.url }})

У каждой записи в mongoDB есть поле `_id`, которое должно быть уникальным в коллекции.
По умолчанию тип этого поля - [ObjectId](http://docs.mongodb.org/manual/reference/object-id/), и оно присваивается автоматически, если поле не заполнено при сохранении.

Давайте рассмотрим, что из себя представляет тип ObjectId.

<!--more-->

Это 12 байт, которые состоят из:

- 4 байта, содержащие количество секунд с начала Unix эпохи
- 3 байта, содержащие идентификатор устройства
- 2 байта, содержащие id процесса
- 3 байта, содержащие счетчик, который стартует со случайного значения

Как видим, первые 4 байта содержат дату создания, и ее можно использовать:

- Сортируя по полю `_id` мы получаем документы в порядке их создания
- Мы можем получить время создания документа, имея только поле `_id`.

Но надо иметь в виду, что эта дата создания доступна с точностью до секунды. Если два документа созданы в течение одной секунды, то их порядок при сортировке по `_id` не определен.

Т.о. если нам достаточна секундная точность, то можем **НЕ** создавать поля наподобие `created_at`:

```javascript
{
    created_at: ISODate("2015-01-18T12:07:47.036Z")
    // остальные поля
}
```

т.к. дата создания содержится в поле `_id`.

### Получение даты из ObjectId

В mongoDB shell дату можно получить с помощью метода [getTimestamp()](http://docs.mongodb.org/manual/reference/method/ObjectId.getTimestamp/#ObjectId.getTimestamp):

```javascript
> db.users.findOne()._id.getTimestamp()
ISODate("2015-01-18T09:07:47Z")
```

А в коде питона - с помощью аттрибута [generation_time](http://api.mongodb.org/python/current/api/bson/objectid.html?highlight=generation_time#bson.objectid.ObjectId.generation_time)

```python
>>> from pymongo import MongoClient
>>> db = MongoClient().db_name
>>> user = db.users.find_one()
>>> user['_id'].generation_time
datetime.datetime(2015, 1, 18, 9, 7, 47, tzinfo=<bson.tz_util.FixedOffset object at 0x10e758d50>)
```

Дата возвращается в UTC, причем в питоне это aware datetime c таймзоной.

На всякий случай, в этих примерах я использовал такие версии:

- mongoDB v2.6.6
- pymongo v2.7.2

P.S. спасибо [@eugeneglybin](https://twitter.com/eugeneglybin) за наводку.
