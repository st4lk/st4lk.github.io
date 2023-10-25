---
layout: post
title:  "Что нужно знать об индексах в mongodb"
date:   2014-03-07 18:19:43 +0000
categories: database mongodb
redirect_from:
  - /2014/mongodb-indexes/
  - /blog/2014/03/07/mongodb-indexes.html
---

[![Что нужно знать об индексах в mongodb](/assets/images/posts/2014-03-07-mongodb-indexes/mongoDB-logo_small.png "Что нужно знать об индексах в mongodb")]({{ site.baseurl }}{{ page.url }})

Недавно закончил курс "M101P: MongoDB for Developers" (он периодически повторяется, например [следующий](https://education.mongodb.com/courses/10gen/M101P/2014_April/about) стартует в апреле).
В процессе прохождения натолкнулся на некоторые интересные моменты.

<!--more-->

### 1. Выбор индекса для запроса.

Допустим у нас коллекция с такими данными:

```javascript
{ "_id" : ..., "a" : 81810, "b" : 97482, "c" : 44288 }
{ "_id" : ..., "a" : 11734, "b" : 27893, "c" : 19485 }
// и т.д.
```

Всего 99999 объектов. У коллекции есть индексы:

```javascript
db.foo.ensureIndex({a: 1, b: 1, c: 1})
db.foo.ensureIndex({c: -1})
```

Вопрос: какой индекс будет использован при запросе

```javascript
db.foo.find({'a':{'$lt':10000}, 'b':{'$gt': 5000}}).sort({'c':-1}) 
```
?

Интуитивно очень хотелось бы, чтобы был использован индекс {a: 1, b: 1, c: 1}, ведь вроде бы он покрывает все нужные нам поля. Но, к сожалению, это не так.

Во-первых, индекс {a: 1, b: 1, c: 1} в этом случае [не может быть](http://docs.mongodb.org/manual/tutorial/sort-results-with-indexes/#use-indexes-to-sort-query-results) использован одновременно для find и для sort, т.к. find содержит операторы сравнения ($lt, $gt). Т.е. в таком запросе 

```javascript
db.foo.find({'a': 1, 'b': 2}).sort({'c':-1})
```

индекс был бы использован полностью. Но, к сожалению, у нас не такой запрос.

Ну ладно, бог с ней с сортировкой, наверно индекс {a: 1, b: 1, c: 1} будет использован только для find, а сортировка уже будет сделана без индексов.
Эх, смотрим:

```javascript
db.foo.find({'a':{'$lt':10000}, 'b':{'$gt': 5000}}).sort({'c':-1}).explain()
{
    "cursor" : "BtreeCursor c_-1",
    "n" : 9498,
    "nscanned" : 99999,
    "scanAndOrder" : false,
    // другие поля не так интересны
}
```

{a: 1, b: 1, c: 1} даже не был задействован, вместо него индекс {c: -1} был использован для сортировки, потому что так решил mongodb'шный query optimizer.

Вот где пригодится принудительный выбор индексов оператором [$hint](http://docs.mongodb.org/manual/reference/operator/meta/hint/):

```javascript
db.foo.find({'a':{'$lt':10000}, 'b':{'$gt': 5000}}, {'a':1, 'c':1}).sort({'c':-1}).hint({a: 1, b: 1, c: 1}).explain()
{
    "cursor" : "BtreeCursor a_1_b_1_c_1",
    "n" : 9498,
    "nscanned" : 9974,
    "scanAndOrder" : true,
    // другие поля не так интересны
}
```

Сейчас индекс использовался для find, а сортировка осуществилась без индексов. Думаю, использовать индекс для фильтрации 9498 элементов из 99999 и затем к ним применить сортировку намного эффективнее нежели применить полный перебор к 99999 элементам и затем сортировку найденных 9498 осуществить с помощью индексов.

### 2. Направление индекса

Возвращаясь к предыдущему примеру, видно, что один из индексов имеет значение "-1":

```javascript
db.foo.ensureIndex({c: -1})
```
Это значит, что создан "нисходящий" индекс по полю "c". Какое это вообще имеет значение?

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

В обоих случаях применился индекс, только во втором случае он использовался в обратном порядке.
Зачем тогда нужно указывать "направление" индекса?

Направление индекса пригодится при сортировке по двум и более полям:

```javascript
db.foo.ensureIndex({a:1, b:1, c:1})

// тут индекс не может быть использован
db.foo.find().sort({a:-1, b:1}).explain()
{
    "cursor" : "BasicCursor",
    "scanAndOrder" : true,
    // ...
}

// а тут - может
db.foo.find().sort({a:1, b:1}).explain()
{
    "cursor" : "BtreeCursor a_1_b_1_c_1",
    "scanAndOrder" : false,
}

// но для сортировки по одному полю направление индекса не важно:
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
Т.е. правило такое: **при сортировке по двум и более полям направление сортировки должно совпадать с направлением индекса для всех полей**.

### 3. Индексы и aggregation

Aggregation - очень, очень классная функция в mongodb. Было бы крайне полезно получать explain данные и об aggregation запросах. Такая возможность появится в версии 2.6 (на момент написания статьи эта версия официально еще не вышла).

Вот как можно будет применить explain в [версии 2.6](http://docs.mongodb.org/master/release-notes/2.6/):

```javascript
db.foo.aggregate([
        {$match: {a: {'$lt':10000}, b: {'$gt': 5000}}},
        {$sort: {c: -1}},
        {$group: {_id: null, a_total: {$sum: "$a"}}}
    ],
    {explain: true}
)
```

Но!
Оказывается, explain можно использовать для aggregation и в [текущей версии 2.4](http://stackoverflow.com/a/19601769/821594), только эта функция не документирована!
Это можно сделать не напрямую, а используя runCommand:

```javascript
db.foo.runCommand('aggregate', {pipeline:[
    {$match: {a: {'$lt':10000}, b: {'$gt': 5000}}},
    {$sort: {c: -1}},
    {$group: {_id: null, a_total: {$sum: "$a"}}}
], explain: true})
```

Вывод будет таким (сокращенно):

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
Вот правда hint к aggregation применить пока нельзя: [SERVER-7944](https://jira.mongodb.org/browse/SERVER-7944).

### P.S. 
Кстати, всем завершившим курс "M101P: MongoDB for Developers" выдают вот такой сертификат: [M101P](https://s3.amazonaws.com/edu-cert.10gen.com/downloads/01739dbdba0e46f7964b160203b4f749/Certificate.pdf).
