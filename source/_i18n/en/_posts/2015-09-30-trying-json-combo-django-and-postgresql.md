---
layout: post
title:  "Trying JSON in Django and PostgreSQL (and compare with MongoDB)"
date:   2015-09-30 18:19:43 +0000
categories: database django mongodb postgresql sql
redirect_from:
  - /2015/trying-json-combo-django-and-postgresql/
  - /blog/2015/09/30/trying-json-combo-django-and-postgresql.html
---

[![Trying JSON in Django and PostgreSQL](https://img-fotki.yandex.ru/get/3706/85893628.c69/0_19430e_cafd0257_XL.png
 "Trying JSON in Django and PostgreSQL")]({{ site.baseurl }}{{ page.url }})

New [JSONField](https://docs.djangoproject.com/en/1.9/ref/contrib/postgres/fields/#jsonfield) will be added in Django 1.9, it can be used with PostgreSQL >= 9.4. Let's try to work with it and find out, in what situations it can be useful.

<!--more-->

Currently django 1.9 alpha is available, final version is scheduled on December 2015.
Alpha can be installed with pip:

    pip install --pre django

Now imagine that we have an e-commerce site, where we offer products of different types. For example, laptops and t-shirts. Obviously, such goods will have different attributes: t-shirts will have size, color and laptops - screen size, CPU frequency, hard drive and so on. One of the approaches to design such data in SQL is [Entity–attribute–value model (EAV)](https://en.wikipedia.org/wiki/Entity%E2%80%93attribute%E2%80%93value_model).

But now we have JSON, so let's try to organise data using this type.

Create simple model for products:

    from django.db import models
    from django.contrib.postgres.fields import JSONField

    class Category(models.Model):
        name = models.CharField(max_length=100)

    class Product(models.Model):
        name = models.CharField(max_length=100)
        category = models.ForeignKey(Category)
        price = models.IntegerField()
        attributes = JSONField()

        def __str__(self):
            return self.name

As we can see, there are several common fields for all products (name, category, price) plus specific to particular product attributes (as JSON field).

Create objects:

    tshirt = Category.objects.create(name='tshirts')
    notebook = Category.objects.create(name='notebook')

    # Tshirts
    Product.objects.create(name='Silk tshirt', category=tshirt, price=100, attributes={
        'colors': ['red', 'black'],
        'sizes': ['S', 'M'],
        'model': 'polo',
        'material': 'silk',
    })

    Product.objects.create(name='Bamboo tshirt', category=tshirt, price=120, attributes={
        'colors': ['white', 'yellow'],
        'sizes': ['M', 'L', 'XL'],
        'model': 'poet',
        'material': 'bamboo',
    })

    # Notebooks
    Product.objects.create(name='MacBook Pro', category=notebook, price=2000, attributes={
        'brand': 'Apple',
        'screen': 15.0,
        'speed': 2200,
        'hd': 256,
    })

    Product.objects.create(name='ATIV Book 9', category=notebook, price=1200, attributes={
        'brand': 'Samsung',
        'screen': 12.2,
        'speed': 2400,
        'hd': 128,
    })

### Queries

Let's see, what queries we can make.

1. Get t-shirts with both 'M' and 'L' sizes:

        >>> Product.objects.filter(category=tshirt, attributes__contains={'sizes': ['M', 'L']})
        [<Product: Bamboo tshirt>]

2. Get t-shirts with both 'M' and 'L' sizes, both white and yellow colors, with poetry on it (model=poet): 

        >>> Product.objects.filter(category=tshirt,
            attributes__contains={'sizes': ['M', 'L'], 'colors': ['white', 'yellow'],
            'model': 'poet'})
        [<Product: Bamboo tshirt>]

3. Get laptops with CPU frequency 2400 and screen size 12.2

        >>> Product.objects.filter(category=notebook,
            attributes__contains={'speed': 2400, 'screen': 12.2})
        [<Product: ATIV Book 9>]

4. Get t-shirts with red color, model polo and with size 'M' or 'L'

        >>> Product.objects.filter(category=tshirt,
            attributes__contains={'colors': ['red'], 'model': 'polo'},
            attributes__sizes__has_any_keys=['M', 'L'])
        [<Product: Silk tshirt>]

5. Get laptops with CPU greater that 2000 and screen larger that 13

        >>> Product.objects.filter(category=notebook, attributes__speed__gt=2000,
            attributes__screen__gt=13)
        [<Product: MacBook Pro>]

6. Get laptops with CPU frequency equal to 2200 or 2400

        >>> Product.objects.filter(category=notebook, attributes__speed__in=(2200, 2400))
        [<Product: ATIV Book 9>, <Product: MacBook Pro>]

    or like this:

        >>> from django.db.models import Q
        >>> Product.objects.filter(category=notebook).filter(
            Q(attributes__contains={'speed': 2200}) | Q(attributes__contains={'speed': 2400}))

### Indexes


Let's find out, how effective can be our queries.

PostgreSQL supports [different indexes](http://www.postgresql.org/docs/9.4/static/datatype-json.html#JSON-INDEXING) for JSON types:

- GIN

    this index in its turn can support different operators:

    - jsonb_ops (default), supports operators `@>, ?, ?&, ?|`
    - jsonb_path_ops, supports only `@>`, but works faster and requires less space

- btree

    can be useful in searching exact json document

- hash

    same as btree, can be useful in searching exact json document


#### Сorrespondence of some Django operations and PostgreSQL operators

    Django        Postgres
    ----------------------
    contains      @>
    contained_by  <@
    has_key       ?
    has_any_keys  ?|
    has_keys      ?&

In our case the most interesting operator is `@>`. Django will transform operation `contains` to it for json fields.

If we simply add `db_index=True`, btree index will be created:

    class Product(models.Model):
        ...
        attributes = JSONField(db_index=True)

For our queries GIN index will be more applicable. To create it we'll use [RunSQL](https://docs.djangoproject.com/en/dev/ref/migration-operations/#django.db.migrations.operations.RunSQL) operation.

First create empty migration. In current example app with products has name 'catalogue_simple'

    python manage.py makemigrations --empty catalogue_simple

In created file (in my case it is 0002_auto_20150928_1610.py) add couple imports and commands to create and discard index:

    from catalogue_simple.models import Product
    from psycopg2.extensions import AsIs

    class Migration(migrations.Migration):
        # ...
        operations = [
            migrations.RunSQL(
                [("CREATE INDEX catalogue_product_attrs_gin ON %s USING gin"
                    "(attributes jsonb_path_ops);", [AsIs(Product._meta.db_table)])],
                [('DROP INDEX catalogue_product_attrs_gin;', None)],
            )
        ]

Here catalogue_product_attrs_gin - index name (we can choose any), attributes - name of JSON field, Product - product model. We are creating jsonb_path_ops index, as it will cover the most common operation in our queries - `contains`. Extension `AsIs` is used to not wrap `%s` param with single quotes.

We don't need btree index, so don't add it:

    class Product(models.Model):
        ...
        attributes = JSONField()

#### Test data

I've generated 1 000 000 products of 4 different categoires, 250 000 in each. Every product category has its own attributes, from 4 to 7 keys. Some values are scalar (t-shirt material), some - lists (t-shirt sizes).

#### Queries and indexes

1. Get t-shirts with both 'M' and 'L' sizes:

        >>> Product.objects.filter(category=tshirt, attributes__contains={'sizes': ['M', 'L']})

    Corresponding SQL (enumeration of all field names is replaced with `*` for brevity):

        SELECT * FROM "catalogue_simple_product" WHERE
        ("catalogue_simple_product"."category_id" = 5
            AND
        "catalogue_simple_product"."attributes" @> '{"sizes": ["M", "L"]}');

    Without GIN index on attributes query time is 292 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/xmWS).

    Same query with GIN index - 250 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/cHk).

    In this case we don't gain much performance (292 ms vs 250 ms), because result contains a lot of rows: 66412.
    It is called "low selectivity".
    Selectivity - ratio of filtered rows to the total rows. If this ratio tends to 1, we say "low selectivity", to 0 - "high selectivity".
    This metric helps us to estimate index effectiveness. With low selectivity index will not gain much performance.

2. Get t-shirts with both 'M' and 'L' sizes, both white and yellow colors, with poetry on it (model=poet):

        >>> Product.objects.filter(category=tshirt,
            attributes__contains={'sizes': ['M', 'L'], 'colors': ['white', 'yellow'],
            'model': 'poet'})

    Corresponding SQL:

        SELECT * FROM "catalogue_simple_product" WHERE
        ("catalogue_simple_product"."category_id" = 5
            AND
        "catalogue_simple_product"."attributes" @> '{
            "colors": ["white", "yellow"],
            "model": "poet",
            "sizes": ["M", "L"]
        }');

    Without GIN index - 240 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/8Zx5).

    With GIN index - 49 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/qYN).

    Query became faster: 240 ms vs 49 ms. Result contains 3737 rows, higher selectivity than in previous request.

3. Get laptops with CPU frequency 2400 and screen size 12.2

        >>> Product.objects.filter(category=notebook,
            attributes__contains={'speed': 2400, 'screen': 12.2})

    Corresponding SQL:

        SELECT * FROM "catalogue_simple_product" WHERE
        ("catalogue_simple_product"."category_id" = 7
            AND
        "catalogue_simple_product"."attributes" @> '{"screen": 12.2, "speed": 2400}');

    Without GIN index - 222 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/Ocgt).

    With GIN index - 34 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/Ik8E).

    222ms vs 34ms. Result contains 10389 rows.

4. Get t-shirts with red color, model polo and with size 'M' or 'L'

        >>> Product.objects.filter(category=tshirt,
            attributes__contains={'colors': ['red'], 'model': 'polo'},
            attributes__sizes__has_any_keys=['M', 'L'])

    Corresponding SQL:

        SELECT * FROM "catalogue_simple_product" WHERE
        ("catalogue_simple_product"."category_id" = 5
            AND
        "catalogue_simple_product"."attributes" @> '{"colors": ["red"], "model": "polo"}'
            AND
        "catalogue_simple_product"."attributes" -> 'sizes' ?| ARRAY['M', 'L']);

    Without GIN index - 253 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/6SJ).

    With GIN index - 78 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/Lgb).

    253 ms vs 78 ms. Result contains 18428 rows. In this query `has_any_keys` _can't_ use index, as we declared _jsonb_path_ops_ index. But index _jsonb_ops_ also will not work, because we are looking for array elements and not for first level keys.
    If such query is common and it has high selectivity, we can create index on particular JSON key:

        CREATE INDEX gin_sizes ON catalogue_simple_product USING gin ((attributes -> 'sizes'));

    But in current example this don't make sense, as filter `"attributes" -> 'sizes' ?| ARRAY['M', 'L']` has low selectivity:

        >>> Product.objects.filter(category=tshirt,
            attributes__contains={'colors': ['red'], 'model': 'polo'},
            attributes__sizes__has_any_keys=['M', 'L']).count()
        18428

        >>> Product.objects.filter(category=tshirt,
            attributes__contains={'colors': ['red'], 'model': 'polo'}).count()
        25162

    Only ~25% of objects are filtered by sizes in this query.

5. Get laptops with CPU greater that 2000 and screen larger that 13

        >>> Product.objects.filter(category=notebook, attributes__speed__gt=2000,
            attributes__screen__gt=13)

    Corresponding SQL:

        SELECT * FROM "catalogue_simple_product" WHERE
        ("catalogue_simple_product"."category_id" = 7
            AND
        "catalogue_simple_product"."attributes" -> 'screen' > '13'
            AND
        "catalogue_simple_product"."attributes" -> 'speed' > '2000')

    GIN index will not help here. If such request is common, we can create btree index on needed JSON keys:

        CREATE INDEX attrs_screen_speed ON catalogue_simple_product ((attributes -> 'screen'), (attributes -> 'speed'));

    Result contains 10536 rows.

    Without btree index query time is 352 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/GWNM).

    With btree index - 46 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/YQO).

6. Get laptops with CPU frequency equal to 2200 or 2400

        >>> Product.objects.filter(category=notebook, attributes__speed__in=(2200, 2400))

    Corresponding SQL:

        SELECT * FROM "catalogue_simple_product" WHERE
        ("catalogue_simple_product"."category_id" = 7
            AND
        "catalogue_simple_product"."attributes" -> 'speed' IN ('2200', '2400'))

    This query is **not** covered by GIN index. Query time ~ 389 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/6U9).

    Let's try to rewrite this query to use existing GIN index

        >>> from django.db.models import Q
        >>> Product.objects.filter(category=notebook).filter(Q(attributes__contains={'speed': 2200}) | Q(attributes__contains={'speed': 2400}))

    SQL:

        SELECT * FROM "catalogue_simple_product" WHERE
        ("catalogue_simple_product"."category_id" = 7
            AND
        ("catalogue_simple_product"."attributes" @> '{"speed": 2200}'
                OR 
        "catalogue_simple_product"."attributes" @> '{"speed": 2400}'));

    Now GIN index can be used, query time ~ 337 ms [EXPLAIN ANALYSE](http://explain.depesz.com/s/Sdq).

    As we see, there is no much difference. But let's check the selectivity of this query.
    Result contains 124 995 rows from 250 000 possible for current category, we have very low selectivity.

    Create 100 laptops with CPU frequency 3200 and 100 laptops with 3500. There are no other laptops with such frequencies in database.

    No check the performance:

    Query doesn't use GIN index:

        >>> Product.objects.filter(category=notebook, attributes__speed__in=(3200, 3500))

    we get the same time ~ 391 ms [EXPLAIN ANALYSE](http://explain.depesz.com/s/ThI).

    Query does use GIN index:

        >>> Product.objects.filter(category=notebook).filter(Q(attributes__contains={'speed': 3200}) | Q(attributes__contains={'speed': 3500}))

    Now we have query time only 0.773 ms! [EXPLAIN ANALYSE](http://explain.depesz.com/s/rqXN).

#### Resume of indexes

We can use single GIN index (jsonb_path_ops) to query by several attributes, and not just by one!

Of course, it is not a silver bullet. We must always take into account, what data is we working with. And consequently choose right design.

### NoSQL database (MongoDB)

Can we store same data and make similar queries in MongoDB (v3.0.6)?

To use only one single index in queries by unknown fields in advance, we need to use different structure in MongoDB.

Field attributes will be a list of embedded documents, that have name and value:

    > db.catalogue_simple.find().pretty()
    {
        "_id" : ObjectId("560ab1970a0a88fe77d00f02"),
        "category" : "tshirts",
        "name" : "Silk tshirt",
        "price" : 100,
        "attributes" : [
            {
                "name" : "colors",
                "value" : "red"
            },
            {
                "name" : "colors",
                "value" : "black"
            },
            {
                "name" : "sizes",
                "value" : "S"
            },
            {
                "name" : "sizes",
                "value" : "M"
            },
            {
                "name" : "model",
                "value" : "polo"
            },
            {
                "name" : "material",
                "value" : "silk"
            }
        ]
    }
    {
        "_id" : ObjectId("560ab1dd0a0a88fe77d00f03"),
        "category" : "tshirts",
        "name" : "Bamboo tshirt",
        "price" : 120,
        "attributes" : [
            {
                "name" : "colors",
                "value" : "white"
            },
            {
                "name" : "colors",
                "value" : "yellow"
            },
            {
                "name" : "sizes",
                "value" : "M"
            },
            {
                "name" : "sizes",
                "value" : "L"
            },
            {
                "name" : "sizes",
                "value" : "XL"
            },
            {
                "name" : "model",
                "value" : "poet"
            },
            {
                "name" : "material",
                "value" : "bamboo"
            }
        ]
    }
    {
        "_id" : ObjectId("560ab2cb0a0a88fe77d00f04"),
        "category" : "notebook",
        "name" : "MacBook Pro",
        "price" : 2000,
        "attributes" : [
            {
                "name" : "brand",
                "value" : "Apple"
            },
            {
                "name" : "screen",
                "value" : 15
            },
            {
                "name" : "speed",
                "value" : 2200
            },
            {
                "name" : "hd",
                "value" : 256
            }
        ]
    }
    {
        "_id" : ObjectId("560ab2ec0a0a88fe77d00f05"),
        "category" : "notebook",
        "name" : "ATIV Book 9",
        "price" : 1200,
        "attributes" : [
            {
                "name" : "brand",
                "value" : "Samsung"
            },
            {
                "name" : "screen",
                "value" : 12.2
            },
            {
                "name" : "speed",
                "value" : 2400
            },
            {
                "name" : "hd",
                "value" : 128
            }
        ]
    }

### Queries (MongoDB)

1. Get t-shirts with both 'M' and 'L' sizes:

        > db.catalogue_simple.find({attributes: {$all: [
            {"$elemMatch": {"name": "sizes", "value": "M"}},
            {"$elemMatch": {"name": "sizes", "value": "L"}}
        ]}, category: 'tshirts'})

        {"name" : "Bamboo tshirt", /* ... */}

2. Get t-shirts with both 'M' and 'L' sizes, both white and yellow colors, with poetry on it (model=poet):

        > db.catalogue_simple.find({attributes: {$all: [
            {"$elemMatch": {"name": "sizes", "value": "M"}},
            {"$elemMatch": {"name": "sizes", "value": "L"}},
            {"$elemMatch": {"name": "colors", "value": "white"}},
            {"$elemMatch": {"name": "colors", "value": "yellow"}},
            {"$elemMatch": {"name": "model", "value": "poet"}}
        ]}, category: 'tshirts'})

        {"name" : "Bamboo tshirt", /* ... */}

3. Get laptops with CPU frequency 2400 and screen size 12.2


        > db.catalogue_simple.find({attributes: {$all: [
            {"$elemMatch": {"name": "speed", "value": 2400}},
            {"$elemMatch": {"name": "screen", "value": 12.2}}
        ]}, category: 'notebook'})

        {"name" : "ATIV Book 9", /* ... */}

4. Get t-shirts with red color, model polo and with size 'M' or 'L'

        > db.catalogue_simple.find({attributes: {$all: [
            {"$elemMatch": {"name": "colors", "value": "red"}},
            {"$elemMatch": {"name": "model", "value": "polo"}},
            {"$elemMatch": {"name": "sizes", "value": {"$in": ["M", "L"]}}}
        ]}, category: 'tshirts'})

        {"name" : "Silk tshirt", /* ... */}

5. Get laptops with CPU greater that 2000 and screen larger that 13

        > db.catalogue_simple.find({attributes: {$all: [
            {"$elemMatch": {"name": "speed", "value": {"$gt": 2000}}},
            {"$elemMatch": {"name": "screen", "value": {"$gt": 13}}}
        ]}, category: 'notebook'})

        {"name" : "MacBook Pro", /* ... */}

6. Get laptops with CPU frequency equal to 2200 or 2400

        > db.catalogue_simple.find({attributes: {$all: [
            {"$elemMatch": {"name": "speed", "value": {"$in": [2200, 2400]}}},
        ]}, category: 'notebook'})

        {"name" : "MacBook Pro", /* ... */}, {"name" : "ATIV Book 9", /* ... */}

### Indexes (MongoDB)

We can create [multikey index](http://docs.mongodb.org/manual/core/index-multikey/#index-arrays-with-embedded-documents):

    > db.catalogue_simple.ensureIndex({"attributes.name" : 1, "attributes.value" : 1})

For fairness, create index on category (django automatically creates it for ForeignKey fields)

    > db.catalogue_simple.ensureIndex({"category": 1})

Keep in mind, that MongoDB will use index only for first filter from $all operator. Although MongoDB docs tells about [index intersection](http://docs.mongodb.org/manual/core/index-intersection/), looks like it can't be used in our case.

Illustrative example. Imagine, that in database there is only 1 product with size "XXXS" and a lot of products with size "M".

We want products, that have both sizes "XXXS" and "M".

Check out the query:

    > db.catalogue_simple.find({attributes: {$all: [
        {"$elemMatch": {"name": "sizes", "value": "M"}},
        {"$elemMatch": {"name": "sizes", "value": "XXXS"}},
    ]}, category: 'tshirts'})

MongoDB will apply index only to "M" value. As a result, many documents will be scanned:

    "nReturned" : 1,
    "executionTimeMillis" : 1902,
    "totalKeysExamined" : 249934,
    "totalDocsExamined" : 249934,

But if we place size "XXXS" to the first position:

    > db.catalogue_simple.find({attributes: {$all: [
        {"$elemMatch": {"name": "sizes", "value": "XXXS"}},
        {"$elemMatch": {"name": "sizes", "value": "M"}},
    ]}, category: 'tshirts'})

only one document will be scanned:

    "nReturned" : 1,
    "executionTimeMillis" : 0,
    "totalKeysExamined" : 1,
    "totalDocsExamined" : 1,

The moral is, put filter with highest selectivity to the first place. Unfortunately, we don't always have such information.

#### Test data (MongoDB)

Test data is exactly the same as in PostgreSQL (only structure is different): 4 categories, 250 000 products in each category, 1 000 000 in total.

#### Queries and indexes (MongoDB)

1. Get t-shirts with both 'M' and 'L' sizes:

        > db.catalogue_simple.find({attributes: {$all: [
            {"$elemMatch": {"name": "sizes", "value": "M"}},
            {"$elemMatch": {"name": "sizes", "value": "L"}}
        ]}, category: 'tshirts'})

    Without multikey index on attributes query time is 706 ms, category index is used.

    Output of `.explain('executionStats')`:

        "winningPlan" : {
            // ...
            "indexName" : "category_1",
        }
        "executionStats" : {
            "nReturned" : 66412,
            "executionTimeMillis" : 706,
            "totalKeysExamined" : 250001,
            "totalDocsExamined" : 250001,
        }

    After creation of multikey index on attributes field nothing changes, as MongoDB optimizer decides, that category index is better (i suppose because of low selectivity of attributes query).

2. Get t-shirts with both 'M' and 'L' sizes, both white and yellow colors, with poetry on it (model=poet):

        > db.catalogue_simple.find({attributes: {$all: [
            {"$elemMatch": {"name": "sizes", "value": "M"}},
            {"$elemMatch": {"name": "sizes", "value": "L"}},
            {"$elemMatch": {"name": "colors", "value": "white"}},
            {"$elemMatch": {"name": "colors", "value": "yellow"}},
            {"$elemMatch": {"name": "model", "value": "poet"}},
        ]}, category: 'tshirts'})

    Behaviour is similar to first query.

    Behaviour can change, if we put higher selective filter to the first place. In test data color is more selective, that size. So, make it first:

        > db.catalogue_simple.find({attributes: {$all: [
                {"$elemMatch": {"name": "colors", "value": "white"}},
                {"$elemMatch": {"name": "sizes", "value": "M"}},
                {"$elemMatch": {"name": "sizes", "value": "L"}},
                {"$elemMatch": {"name": "colors", "value": "yellow"}},
                {"$elemMatch": {"name": "model", "value": "poet"}},
            ]}, category: 'tshirts'}).explain('executionStats')

    Explain:

        "winningPlan" : {
            // ...
            "indexName" : "attributes.name_1_attributes.value_1",
        }
        "executionStats" : {
            "nReturned" : 3737,
            "executionTimeMillis" : 658,
            "totalKeysExamined" : 124902,
            "totalDocsExamined" : 124902,
        }

    Query time - 658 ms.

3. Get laptops with CPU frequency 2400 and screen size 12.2

    Same as points 1 and 2.

4. Get t-shirts with red color, model polo and with size 'M' or 'L'

    Same as points 1 and 2.

5. Get laptops with CPU greater that 2000 and screen larger that 13

        > db.catalogue_simple.find({attributes: {$all: [
            {"$elemMatch": {"name": "speed", "value": {"$gt": 2000}}},
            {"$elemMatch": {"name": "screen", "value": {"$gt": 13}}}
        ]}, category: 'notebook'}).explain('executionStats')

    Remember, PostgreSQL can't use GIN index in such a query.
    But multikey index in current data structure can work.

    We have good selectivity for speed in this request:

        "winningPlan" : {
            // ...
            "indexName" : "attributes.name_1_attributes.value_1",
        }
        "executionStats" : {
            "nReturned" : 10536,
            "executionTimeMillis" : 160,
            "totalKeysExamined" : 62472,
            "totalDocsExamined" : 62472,
        }

6. Get laptops with CPU frequency equal to 2200 or 2400

    Same as previous points.

### Resume

PostgreSQL 9.4 introduced new type jsonb. It can be used effectively in queries. And we can use single index to query on different json keys. Not all operations are available (for example greater than/less than, we need a separate index on particular key), but anyway this is incredibly useful for a wide range of tasks. And starting from Django 1.9 this functionality is available out of the box.

MongoDB doesn't have analogue to `@>` operator. We can adopt the structure of data to make similar queries, using one index. But it is less effective, than in PostgreSQL. Because index is applied only to one key. On the other hand MongoDB support higher range of operations when filtering on _any_ _one_ key, using single index.

I really like JSON in PostgreSQL, it can be used in many tasks. And we have all advantages of SQL: joins and transactions, that are not presented in MongoDB. And now it is supported by Django ORM.

### Useful links

- [Django JSONField docs](https://docs.djangoproject.com/en/dev/ref/contrib/postgres/fields/#jsonfield)
- [PostgreSQL JSON type docs](http://www.postgresql.org/docs/9.4/static/datatype-json.html)
- [PostgreSQL JSON functions and operations docs](http://www.postgresql.org/docs/9.4/static/functions-json.html)
- [Christophe Pettus - PostgreSQL Proficiency for Python People - PyCon 2015 (video)](http://www.youtube.com/watch?v=78A2gJBgL9g)
- [PostgreSQL and JSON: 2015. Christophe Pettus. PGConf US 2015 (slides)](http://thebuild.com/presentations/json2015-pgconfus.pdf)
- [Asya Kamsky, Yandex 2014 MongoDB meetup](https://events.yandex.ru/lib/talks/1707/)
