---
layout: post
title:  "What you should know about mongodb indexes"
date:   2014-03-07 18:19:43 +0000
categories: database mongodb
redirect_from:
  - /2014/mongodb-indexes/
---

[![What it is needed to know about mongodb indexes](/assets/images/posts/2014-03-07-mongodb-indexes/mongoDB-logo_small.png "What it is needed to know about mongodb indexes")]({{ site.baseurl }}{{ page.url }})

Recently i've completed course "M101P: MongoDB for Developers" (periodically repeats, [next](https://education.mongodb.com/courses/10gen/M101P/2014_April/about) starts at April).
During this course i've found to myself interesting features of mongodb.

<!--more-->

### 1. Index selection.

Suppose we have collection with such document format:

```javascript
{ "_id" : ..., "a" : 81810, "b" : 97482, "c" : 44288 }
{ "_id" : ..., "a" : 11734, "b" : 27893, "c" : 19485 }
// and so on.
```

Total 99999 documents. Collection has indexes:

```javascript
db.foo.ensureIndex({a: 1, b: 1, c: 1})
db.foo.ensureIndex({c: -1})
```

Question: what index will be used in query

```javascript
db.foo.find({'a':{'$lt':10000}, 'b':{'$gt': 5000}}).sort({'c':-1}) 
```

?

Intuitively this: {a: 1, b: 1, c: 1}, as it fully covers all needed fields. But, unfortunately, it is not.

Firstly, index {a: 1, b: 1, c: 1} [can't be](http://docs.mongodb.org/manual/tutorial/sort-results-with-indexes/#use-indexes-to-sort-query-results) used simultaneously for find and sort, because find contains compare operators ($lt, $gt).

Index can be used in such query

```javascript
db.foo.find({'a': 1, 'b': 2}).sort({'c':-1})
```

But, as you see, we have another query.

Well, ok. Probably index {a: 1, b: 1, c: 1} will be used only for find, and sort will be applied without index.

Ah, look:

```javascript
db.foo.find({'a':{'$lt':10000}, 'b':{'$gt': 5000}}).sort({'c':-1}).explain()
{
    "cursor" : "BtreeCursor c_-1",
    "n" : 9498,
    "nscanned" : 99999,
    "scanAndOrder" : false,
    // other fields not interesting now
}
```

{a: 1, b: 1, c: 1} index not even been used, and {c: -1} index was used only for sorting, because it is a decision of mongodb query optimizer.

That's where manual index selection will be useful by [$hint](http://docs.mongodb.org/manual/reference/operator/meta/hint/) operator:

```javascript
db.foo.find({'a':{'$lt':10000}, 'b':{'$gt': 5000}}, {'a':1, 'c':1}).sort({'c':-1}).hint({a: 1, b: 1, c: 1}).explain()
{
    "cursor" : "BtreeCursor a_1_b_1_c_1",
    "n" : 9498,
    "nscanned" : 9974,
    "scanAndOrder" : true,
    // other fields not interesting now
}
```

Now index was used for find operation. Sort was performed without index. I think, that using index for filtering 9498 documents from 99999 and then sorting in memory much effective than apply full scan for 99999 documents and then sort 9498 elements using index.

### 2. Index direction

You've mention, that in previous example one of indexes has value "-1":

```javascript
db.foo.ensureIndex({c: -1})
```

It means "descending" index for key "c". What the sense in that?

```javascript
db.foo.find().sort({'c':-1}).explain()
{
    "cursor" : "BtreeCursor c_-1",
    // ...
}

db.foo.find().sort({'c':1}).explain()
{
    "cursor" : "BtreeCursor c_-1 reverse",
    // ...
}
```

Index was applied in both cases, but in second one it has a "reverse" order.

Why it is needed to specify direction?

It make sense when sorting on two or more fields:

```javascript
db.foo.ensureIndex({a:1, b:1, c:1})

// index can't be used
db.foo.find().sort({a:-1, b:1}).explain()
{
    "cursor" : "BasicCursor",
    "scanAndOrder" : true,
    // ...
}

// but here - can
db.foo.find().sort({a:1, b:1}).explain()
{
    "cursor" : "BtreeCursor a_1_b_1_c_1",
    "scanAndOrder" : false,
}

// but for one field sorting any direction is good:
db.foo.find().sort({a:1}).explain()
{
    "cursor" : "BtreeCursor a_1_b_1_c_1",
    "scanAndOrder" : false,
}
db.foo.find().sort({a:-1}).explain()
{
    "cursor" : "BtreeCursor a_1_b_1_c_1 reverse",
    "scanAndOrder" : false,
}
```

So the rule is: **when sorting on two or more fields index direction must be equal to all field directions being sorted by**.

### 3. Indexes and aggregation

Aggregation is a very, very cool feature in mongodb. The ability to get .explain() data for aggregation queries is important. Such ability will be added in version 2.6 (when i write this post version 2.6 is not officially released).

Here how we can do it in [version 2.6](http://docs.mongodb.org/master/release-notes/2.6/):

```javascript
db.foo.aggregate([
    {$match: {a: {'$lt':10000}, b: {'$gt': 5000}}},
    {$sort: {c: -1}},
    {$group: {_id: null, a_total: {$sum: "$a"}}}
],
{explain: true}
)
```

But! 
It turns out, that we can get explain data even in [current version 2.4](http://stackoverflow.com/a/19601769/821594), but this feature is not documented!
We can do it not directly, but with runCommand:

```javascript
db.foo.runCommand('aggregate', {pipeline:[
    {$match: {a: {'$lt':10000}, b: {'$gt': 5000}}},
    {$sort: {c: -1}},
    {$group: {_id: null, a_total: {$sum: "$a"}}}
], explain: true})

```
Output (clipped):

```javascript
{
    "serverPipeline" : [
        {
            "query" : {
                "a" : {
                    "$lt" : 10000
                },
                "b" : {
                    "$gt" : 5000
                }
            },
            "sort" : {
                "c" : -1
            },
            // ...
            "cursor" : {
                "cursor" : "BtreeCursor c_-1",
                "n" : 9498,
                "nscanned" : 99999,
                "scanAndOrder" : false,
                // ..
            },
            // ...
    ],
    "ok" : 1
}
```

Currently, $hint can't be applied to aggregation: [SERVER-7944](https://jira.mongodb.org/browse/SERVER-7944).

### P.S. 
By the way, every student, that complete the course "M101P: MongoDB for Developers", receive such certificate: [M101P](https://s3.amazonaws.com/edu-cert.10gen.com/downloads/01739dbdba0e46f7964b160203b4f749/Certificate.pdf).
