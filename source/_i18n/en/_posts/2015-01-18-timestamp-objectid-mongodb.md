---
layout: post
title:  "Timestamp and ObjectId in mongoDB"
date:   2015-01-18 18:19:43 +0000
categories: database mongodb
redirect_from:
  - /2015/timestamp-objectid-mongodb/
---

[![Timestamp and ObjectId in mongoDB](https://img-fotki.yandex.ru/get/17859/85893628.c67/0_16f717_c4a5da7b_orig.png "Timestamp and ObjectId in mongoDB")]({{ site.baseurl }}{{ page.url }})

Every record in mongoDB has field `_id`, that must be unique inside collection.
By default type of this field is [ObjectId](http://docs.mongodb.org/manual/reference/object-id/),
and it is assigned automatically if field is not set.

Lets look at ObjectId more carefully.

<!--more-->

It is 12 bytes that includes:

- a 4-byte value representing the seconds since the Unix epoch,
- a 3-byte machine identifier,
- a 2-byte process id, and
- a 3-byte counter, starting with a random value.

As we see, first 4 bytes represent creation date and we can use it:

- sort by field `_id` and you'll get documents in creation time order
- we can get creation time of the document from ObjectId

But keep in mind, that this date has accuracy of seconds. If two documents are created
during one second then their order is not defined in sorting by `_id`.

So, if accuracy of second is enough for us then we do **NOT** need field like this:

```javascript
{
    created_at: ISODate("2015-01-18T12:07:47.036Z")
    // other fields
}
```

as creation date is included in `_id`.

### Get date from ObjectId

In mongoDB shell date can be retrieved by method [getTimestamp()](http://docs.mongodb.org/manual/reference/method/ObjectId.getTimestamp/#ObjectId.getTimestamp):

```javascript
> db.users.findOne()._id.getTimestamp()
ISODate("2015-01-18T09:07:47Z")
```

And in python code - by attribute [generation_time](http://api.mongodb.org/python/current/api/bson/objectid.html?highlight=generation_time#bson.objectid.ObjectId.generation_time)

```python
>>> from pymongo import MongoClient
>>> db = MongoClient().db_name
>>> user = db.users.find_one()
>>> user['_id'].generation_time
datetime.datetime(2015, 1, 18, 9, 7, 47, tzinfo=<bson.tz_util.FixedOffset object at 0x10e758d50>)
```

Date is returned in UTC and in python it is aware datetime with timezone.

To be clear, these versions i use:

- mongoDB v2.6.6
- pymongo v2.7.2

P.S. thanks [@eugeneglybin](https://twitter.com/eugeneglybin) to pointing out.
