---
layout: post
title:  "Пробуем JSON в Django и PostgreSQL (и сравниваем с MongoDB)"
date:   2015-09-30 18:19:43 +0000
categories: database django mongodb postgresql sql
redirect_from:
  - /2015/trying-json-combo-django-and-postgresql/
  - /blog/2015/09/30/trying-json-combo-django-and-postgresql.html
---

[![Пробуем JSON в Django и PostgreSQL](https://img-fotki.yandex.ru/get/3706/85893628.c69/0_19430e_cafd0257_XL.png
 "Пробуем JSON в Django и PostgreSQL")]({{ site.baseurl }}{{ page.url }})

В Django 1.9 будет добавлено поле [JSONField](https://docs.djangoproject.com/en/1.9/ref/contrib/postgres/fields/#jsonfield), его можно использовать с базой данных PostgreSQL >= 9.4. Давайте попробуем с ним поработать и оценить, насколько оно удобно.

<!--more-->

На данный момент доступна альфа версия django 1.9, финальная запланирована на декабрь 2015.
Установить альфа версию можно так:

    pip install --pre django

Итак представим, что у нас есть интернет магазин, в котором мы предлагаем товары разных типов. Например, ноутбуки и футболки. Очевидно, что у таких товаров будет разный набор параметров: у футболок будет размер, цвет, а у ноутбуков - размер экрана, частота процессора, объем жесткого диска и прочее.
Один из подходов для работы с такими данными в SQL - [Entity–attribute–value model (EAV)](https://en.wikipedia.org/wiki/Entity%E2%80%93attribute%E2%80%93value_model).

Но теперь у нас есть JSON, попробуем организовать данные с помощью этого типа.

Создадим простейшую модель для товаров:

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

Как видим, у нас будет несколько общих полей для всех товаров (name, category, price), а также специфичные для каждого наименования атрибуты (attributes) в виде поля JSON.

Создадим несколько объектов:

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

### Запросы

Посмотрим, какие запросы мы можем делать.

1. Получить все футболки размера 'M' и 'L' (у товара есть оба размера):

        >>> Product.objects.filter(category=tshirt, attributes__contains={'sizes': ['M', 'L']})
        [<Product: Bamboo tshirt>]

2. Получить все футболки с размерами 'M' и 'L', белого и желтого цветов, с надписей (model = poet):

        >>> Product.objects.filter(category=tshirt,
            attributes__contains={'sizes': ['M', 'L'], 'colors': ['white', 'yellow'],
            'model': 'poet'})
        [<Product: Bamboo tshirt>]

3. Получить все ноутбуки с частотой процессора 2400 и диагональю экрана 12.2

        >>> Product.objects.filter(category=notebook,
            attributes__contains={'speed': 2400, 'screen': 12.2})
        [<Product: ATIV Book 9>]

4. Получить все футболки красного цвета, поло, с размерами 'M' или 'L'

        >>> Product.objects.filter(category=tshirt,
            attributes__contains={'colors': ['red'], 'model': 'polo'},
            attributes__sizes__has_any_keys=['M', 'L'])
        [<Product: Silk tshirt>]


5. Получить все ноутбуки с частотой процессора свыше 2000 и диагональю экрана больше 13

        >>> Product.objects.filter(category=notebook, attributes__speed__gt=2000,
            attributes__screen__gt=13)
        [<Product: MacBook Pro>]

6. Получить все ноутбуки с частотой процессора 2200 или 2400

        >>> Product.objects.filter(category=notebook, attributes__speed__in=(2200, 2400))
        [<Product: ATIV Book 9>, <Product: MacBook Pro>]

    или так:

        >>> from django.db.models import Q
        >>> Product.objects.filter(category=notebook).filter(
            Q(attributes__contains={'speed': 2200}) | Q(attributes__contains={'speed': 2400}))

### Индексы

Посмотрим, насколько эффективны могут быть наши запросы.

В PostgreSQL для JSON полей можно применять [разные индексы](http://www.postgresql.org/docs/9.4/static/datatype-json.html#JSON-INDEXING):

- GIN

    данный индекс в свою очередь может поддерживать различные операторы:

    - jsonb_ops (по умолчанию), поддерживает операторы `@>, ?, ?&, ?|`
    - jsonb_path_ops, поддерживает только оператор `@>`, но работает быстрее и занимает меньше места

- btree

    может быть полезен только для поиска полного соответствия json документов

- hash

    как и btree, полезен для поиска полного соответствия json документов

#### Соответсвие некоторых операций в django и postgres операторов

    Django        Postgres
    ----------------------
    contains      @>
    contained_by  <@
    has_key       ?
    has_any_keys  ?|
    has_keys      ?&

В нашем случае наиболее интересный оператор - `@>`, именно в него django транслирует фильтр `contains` для json полей.

Если мы просто добавим `db_index=True`, будет создан btree индекс:

    class Product(models.Model):
        ...
        attributes = JSONField(db_index=True)

Для наших запросов намного полезней будет GIN индекс. Для его создания воспользуемся операцией [RunSQL](https://docs.djangoproject.com/en/dev/ref/migration-operations/#django.db.migrations.operations.RunSQL).

Сперва создадим пустую миграцию. В моем случае приложение с товарами называется catalogue_simple

    python manage.py makemigrations --empty catalogue_simple

В созданном файле (у меня это 0002_auto_20150928_1610.py) добавим пару импортов, а также команды для создания и отката индекса:

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

Здесь catalogue_product_attrs_gin - это название индекса (выбираем сами), attributes - название JSON поля, Product - модель товара. Создаем индекс jsonb_path_ops, т.к. в основном нам будет интересна только операция contains.
Конструкция AsIs нужна, чтобы соответствующий параметр `%s` не оборачивался в одиночные кавычки.

А btree индекс нам не нужен, поэтому не будем добавлять `db_index=True`:

    class Product(models.Model):
        ...
        attributes = JSONField()

#### Тестовые данные

Я сгенерил 1 000 000 товаров 4-х разных категорий, по 250 000 в каждой. У каждой категории товаров - свои атрибуты, от 4-х до 7. Некоторые значения - скалярные величины (material у футболок), некоторые - списки (sizes у футболок).

#### Запросы по индексам

1. Получить все футболки размера 'M' и 'L' (у товара есть оба размера):

        >>> Product.objects.filter(category=tshirt, attributes__contains={'sizes': ['M', 'L']})

    Соответсвующий SQL (я заменил перечисление всех полей на `*` для краткости):

        SELECT * FROM "catalogue_simple_product" WHERE
        ("catalogue_simple_product"."category_id" = 5
            AND
        "catalogue_simple_product"."attributes" @> '{"sizes": ["M", "L"]}');

    Без GIN индекса для поля attributes запрос выполняется 292 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/xmWS).

    Этот же запрос после создания GIN индекса для поля attributes - 250 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/cHk).

    В данном случае большого выйгрыша мы не получили (было 292ms, стало 250ms), но это потому что результат содержит много строк: 66412.
    Это называется "low selectivity".
    Selectivity - отношение отфильтрованных записей к их общему числу. Если это отношение стремится к 1, говорят low selectivity, если к 0 - high selectivity.
    С помощью этого показателя можно оценить эффективность индекса. При low selectivity индекс не принесет особой пользы.

2. Получить все футболки с размерами 'M' и 'L', белого и желтого цветов, с надписей (model = poet):

        >>> Product.objects.filter(category=tshirt,
            attributes__contains={'sizes': ['M', 'L'], 'colors': ['white', 'yellow'],
            'model': 'poet'})

    Соответствующий SQL:

        SELECT * FROM "catalogue_simple_product" WHERE
        ("catalogue_simple_product"."category_id" = 5
            AND
        "catalogue_simple_product"."attributes" @> '{
            "colors": ["white", "yellow"],
            "model": "poet",
            "sizes": ["M", "L"]
        }');

    Без GIN индекса - 240 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/8Zx5).

    После создания GIN индекса - 49 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/qYN).

    Прирост заметен: 240 ms vs 49 ms. Запрос возращает 3737 строк, большая selectivity чем в предыдущем запросе.

3. Получить все ноутбуки с частотой процессора 2400 и диагональю экрана 12.2

        >>> Product.objects.filter(category=notebook,
            attributes__contains={'speed': 2400, 'screen': 12.2})

    Соответствующий SQL:

        SELECT * FROM "catalogue_simple_product" WHERE
        ("catalogue_simple_product"."category_id" = 7
            AND
        "catalogue_simple_product"."attributes" @> '{"screen": 12.2, "speed": 2400}');

    Без GIN индекса - 222 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/Ocgt).

    После создания GIN индекса - 34 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/Ik8E).

    222ms vs 34ms. Запрос возращает 10389 строк.

4. Получить все футболки красного цвета, поло, с размерами 'M' или 'L'

        >>> Product.objects.filter(category=tshirt,
            attributes__contains={'colors': ['red'], 'model': 'polo'},
            attributes__sizes__has_any_keys=['M', 'L'])

    Соответствующий SQL:

        SELECT * FROM "catalogue_simple_product" WHERE
        ("catalogue_simple_product"."category_id" = 5
            AND
        "catalogue_simple_product"."attributes" @> '{"colors": ["red"], "model": "polo"}'
            AND
        "catalogue_simple_product"."attributes" -> 'sizes' ?| ARRAY['M', 'L']);

    Без GIN индекса - 253 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/6SJ).

    После создания GIN индекса - 78 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/Lgb).

    253 ms против 78 ms. Запрос возвращает 18428 строк. В этом запросе операция `has_any_keys`
    никак не может использовать индекс, т.к. мы объявили индекс вида jsonb_path_ops.
    Однако, запрос вида `"attributes" -> 'sizes' ?| ARRAY['M', 'L']` не будет использовать и jsonb_ops индекс, т.к. мы ищем не по ключам первого уровня, а по значениям списка.
    Если нам часто нужен такой запрос и у него будет большая selectivity, то можно создать индекс именно на этот ключ в JSON поле. Примерно так:

        CREATE INDEX gin_sizes ON catalogue_simple_product USING gin ((attributes -> 'sizes'));

    Но в нашем случае этого делать не нужно, т.к. фильтр `"attributes" -> 'sizes' ?| ARRAY['M', 'L']` обладет низкой selectivity:

        >>> Product.objects.filter(category=tshirt,
            attributes__contains={'colors': ['red'], 'model': 'polo'},
            attributes__sizes__has_any_keys=['M', 'L']).count()
        18428

        >>> Product.objects.filter(category=tshirt,
            attributes__contains={'colors': ['red'], 'model': 'polo'}).count()
        25162

    Т.е. по размеру мы отфильтровываем лишь ~25%.

5. Получить все ноутбуки с частотой процессора свыше 2000 и диагональю экрана больше 13

        >>> Product.objects.filter(category=notebook, attributes__speed__gt=2000,
            attributes__screen__gt=13)

    Соответствующий SQL:

        SELECT * FROM "catalogue_simple_product" WHERE
        ("catalogue_simple_product"."category_id" = 7
            AND
        "catalogue_simple_product"."attributes" -> 'screen' > '13'
            AND
        "catalogue_simple_product"."attributes" -> 'speed' > '2000')

    В данном случае GIN индекс нам не поможет. Если такие запросы используются часто,
    возможно имеет смысл создать btree индекс по конкретным ключам из JSON поля:

        CREATE INDEX attrs_screen_speed ON catalogue_simple_product ((attributes -> 'screen'), (attributes -> 'speed'));

    Запрос возвращает 10536 строк.

    Без btree индекса attrs_screen_speed - 352 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/GWNM)

    После создания btree индекса attrs_screen_speed - 46 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/YQO).



6. Получить все ноутбуки с частотой процессора 2200 или 2400

        >>> Product.objects.filter(category=notebook, attributes__speed__in=(2200, 2400))

    Соответствующий SQL:

        SELECT * FROM "catalogue_simple_product" WHERE
        ("catalogue_simple_product"."category_id" = 7
            AND
        "catalogue_simple_product"."attributes" -> 'speed' IN ('2200', '2400'))

    Этот запрос **не** покрывается нашим GIN индексом. Время выполнения ~ 389 ms, [EXPLAIN ANALYSE](http://explain.depesz.com/s/6U9).

    Попробуем переписать этот же запрос с использованием существующего GIN индекса

        >>> from django.db.models import Q
        >>> Product.objects.filter(category=notebook).filter(Q(attributes__contains={'speed': 2200}) | Q(attributes__contains={'speed': 2400}))

    SQL:

        SELECT * FROM "catalogue_simple_product" WHERE
        ("catalogue_simple_product"."category_id" = 7
            AND
        ("catalogue_simple_product"."attributes" @> '{"speed": 2200}'
                OR 
        "catalogue_simple_product"."attributes" @> '{"speed": 2400}'));

    Здесь GIN индекс может быть использован, время выполнения ~ 337 ms [EXPLAIN ANALYSE](http://explain.depesz.com/s/Sdq).

    Особой разницы нет. Однако, посмотрим на selectivity данного запроса.
    В результате мы имеем 124 995 строк из 250 000 возможных для данной категории, т.е. имеем очень низкий selectivty.

    Создадим 100 ноутбуков с частотой процессора 3200 и 100 ноутбуков с частотой 3500. Других ноутбуков с такими скоростями в БД нет.
    Посмотрим насколько эффективно будет использовать индекс в этом случае.

    Запрос без GIN индекса:

        >>> Product.objects.filter(category=notebook, attributes__speed__in=(3200, 3500))

    Получаем те же ~ 391 ms [EXPLAIN ANALYSE](http://explain.depesz.com/s/ThI).

    Теперь запрос, в котором может быт использован GIN индекс:

        >>> Product.objects.filter(category=notebook).filter(Q(attributes__contains={'speed': 3200}) | Q(attributes__contains={'speed': 3500}))

    В итоге получаем время выполнения лишь 0.773 ms! [EXPLAIN ANALYSE](http://explain.depesz.com/s/rqXN).

#### Резюме по индексам

Как мы видим, мы можем использовать один индекс GIN (jsonb_path_ops) в запросах по всем атрибутам, а не по одному конкретному ключу!
Конечно, это не серебряная пуля, всегда нужно анализировать те данные, с которыми мы работаем и выбирать индексы исходя из нужных запросов.

### NoSQL database (MongoDB)

Давайте посмотрим, как мы можем хранить те же данные и выполнять аналогичные запросы в MongoDB (v3.0.6).

Для того, чтобы использовать один индекс при фильтрации по неизвестным заранее полям в MongoDB, нам нужно будет использовать немного другую структуру данных.

Поле attributes у нас будет списком, а значения - вложенные документы с ключами name и value:

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

### Запросы (MongoDB)

1. Получить все футболки размера 'M' и 'L' (у товара есть оба размера):

        > db.catalogue_simple.find({attributes: {$all: [
            {"$elemMatch": {"name": "sizes", "value": "M"}},
            {"$elemMatch": {"name": "sizes", "value": "L"}}
        ]}, category: 'tshirts'})

        {"name" : "Bamboo tshirt", /* ... */}

2. Получить все футболки с размерами 'M' и 'L', белого и желтого цветов, с надписей (model = poet):

        > db.catalogue_simple.find({attributes: {$all: [
            {"$elemMatch": {"name": "sizes", "value": "M"}},
            {"$elemMatch": {"name": "sizes", "value": "L"}},
            {"$elemMatch": {"name": "colors", "value": "white"}},
            {"$elemMatch": {"name": "colors", "value": "yellow"}},
            {"$elemMatch": {"name": "model", "value": "poet"}}
        ]}, category: 'tshirts'})

        {"name" : "Bamboo tshirt", /* ... */}

3. Получить все ноутбуки с частотой процессора 2400 и диагональю экрана 12.2


        > db.catalogue_simple.find({attributes: {$all: [
            {"$elemMatch": {"name": "speed", "value": 2400}},
            {"$elemMatch": {"name": "screen", "value": 12.2}}
        ]}, category: 'notebook'})

        {"name" : "ATIV Book 9", /* ... */}

4. Получить все футболки красного цвета, поло, с размерами 'M' или 'L'

        > db.catalogue_simple.find({attributes: {$all: [
            {"$elemMatch": {"name": "colors", "value": "red"}},
            {"$elemMatch": {"name": "model", "value": "polo"}},
            {"$elemMatch": {"name": "sizes", "value": {"$in": ["M", "L"]}}}
        ]}, category: 'tshirts'})

        {"name" : "Silk tshirt", /* ... */}

5. Получить все ноутбуки с частотой процессора свыше 2000 и диагональю экрана больше 13

        > db.catalogue_simple.find({attributes: {$all: [
            {"$elemMatch": {"name": "speed", "value": {"$gt": 2000}}},
            {"$elemMatch": {"name": "screen", "value": {"$gt": 13}}}
        ]}, category: 'notebook'})

        {"name" : "MacBook Pro", /* ... */}

6. Получить все ноутбуки с частотой процессора 2200 или 2400

        > db.catalogue_simple.find({attributes: {$all: [
            {"$elemMatch": {"name": "speed", "value": {"$in": [2200, 2400]}}},
        ]}, category: 'notebook'})

        {"name" : "MacBook Pro", /* ... */}, {"name" : "ATIV Book 9", /* ... */}

### Индексы (MongoDB)

В данной орагнизации данных мы можем создать [multikey index](http://docs.mongodb.org/manual/core/index-multikey/#index-arrays-with-embedded-documents):

    > db.catalogue_simple.ensureIndex({"attributes.name" : 1, "attributes.value" : 1})

Для честного сравнения создадим индекс по полю category (django автоматически создает его для ForeignKey полей)

    > db.catalogue_simple.ensureIndex({"category": 1})

Еще следует учитывать, что mongodb будет использовать индекс только для первого фильтра оператора $all. Хоть в доках MongoDB говорится о [index intersesection](http://docs.mongodb.org/manual/core/index-intersection/), однако похоже, что пересечение индексов не работает в данных запросах.

Наглядный пример. Пусть у нас в базе только 1 товар с размером "XXXS", и очень много товаров с размером "M".

Мы хотим найти товары, у которых есть оба размера "XXXS" и "M".

Можем сделать такой запрос:

    > db.catalogue_simple.find({attributes: {$all: [
        {"$elemMatch": {"name": "sizes", "value": "M"}},
        {"$elemMatch": {"name": "sizes", "value": "XXXS"}},
    ]}, category: 'tshirts'})

В этом случае MongoDB применит индекс к значению "M". В итоге будет просканированно много сущностей, затрачено много времени, а в результате только 1 документ:

    "nReturned" : 1,
    "executionTimeMillis" : 1902,
    "totalKeysExamined" : 249934,
    "totalDocsExamined" : 249934,

А если сделаем запрос так ("XXXS" на первом месте):

    > db.catalogue_simple.find({attributes: {$all: [
        {"$elemMatch": {"name": "sizes", "value": "XXXS"}},
        {"$elemMatch": {"name": "sizes", "value": "M"}},
    ]}, category: 'tshirts'})

то результат получим сразу:

    "nReturned" : 1,
    "executionTimeMillis" : 0,
    "totalKeysExamined" : 1,
    "totalDocsExamined" : 1,

Мораль такая, что на первое место нужно ставить поле с наибольшим selectivity. Если у нас конечно есть такая инфорамция.

#### Тестовые данные (MongoDB)

Тестовые данные полностью идентичны использованным в PostgreSQL (за исключением структуры): 4 категории, по 250 000 товаров в каждой, всего 1 000 000.

#### Запросы по индексам (MongoDB)

1. Получить все футболки размера 'M' и 'L' (у товара есть оба размера):

        > db.catalogue_simple.find({attributes: {$all: [
            {"$elemMatch": {"name": "sizes", "value": "M"}},
            {"$elemMatch": {"name": "sizes", "value": "L"}}
        ]}, category: 'tshirts'})

    Без индекса по attributes запрос выполняется 706 ms, используется индекс category.

    Вывод `.explain('executionStats')`:

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


    С индексом по attributes ничего не меняется, т.к. optimizer не считает этот индекс лучше чем category (видимо малая selectivity).

2. Получить все футболки с размерами 'M' и 'L', белого и желтого цветов, с надписей (model = poet):

        > db.catalogue_simple.find({attributes: {$all: [
            {"$elemMatch": {"name": "sizes", "value": "M"}},
            {"$elemMatch": {"name": "sizes", "value": "L"}},
            {"$elemMatch": {"name": "colors", "value": "white"}},
            {"$elemMatch": {"name": "colors", "value": "yellow"}},
            {"$elemMatch": {"name": "model", "value": "poet"}},
        ]}, category: 'tshirts'})

    Ситуация аналогична первому примеру.

    Она может поменяться, если на первое место мы поставим значение с большой selectivity. В тестовых данных цветов больше, чем размеров. Поэтому, если поставить цвет на первое место, то будет использоваться индекс attributes:

        > db.catalogue_simple.find({attributes: {$all: [
                {"$elemMatch": {"name": "colors", "value": "white"}},
                {"$elemMatch": {"name": "sizes", "value": "M"}},
                {"$elemMatch": {"name": "sizes", "value": "L"}},
                {"$elemMatch": {"name": "colors", "value": "yellow"}},
                {"$elemMatch": {"name": "model", "value": "poet"}},
            ]}, category: 'tshirts'}).explain('executionStats')

    Вывод:

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

    Время запроса - 658 ms.

3. Получить все ноутбуки с частотой процессора 2400 и диагональю экрана 12.2

    Аналогично пунктам 1 и 2.

4. Получить все футболки красного цвета, поло, с размерами 'M' или 'L'

    Аналогично пунктам 1 и 2.

5. Получить все ноутбуки с частотой процессора свыше 2000 и диагональю экрана больше 13

        > db.catalogue_simple.find({attributes: {$all: [
            {"$elemMatch": {"name": "speed", "value": {"$gt": 2000}}},
            {"$elemMatch": {"name": "screen", "value": {"$gt": 13}}}
        ]}, category: 'notebook'}).explain('executionStats')

    Как мы помним, в PostgreSQL мы не могли использовать GIN индекс для этого запроса.
    Однако в случае структуры данных, которую мы используем в MongoDB, существующий индекс будет работать.
    Вопрос лишь в том, какой процент данных этот фильтр отсекает.
    Тут selectivity оказалась относительно хорошей:

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

6. Получить все ноутбуки с частотой процессора 2200 или 2400

    Аналогично предыдущим пунктам.

### Итоги

В PostgreSQL 9.4 появился тип jsonb, который можно эффективно использовать в запросах.
Причем создав лишь один индекс мы можем фильтровать по всем ключам из JSON. Не все операции будут доступны (например больше/меньше, для них придется создавать отдельный индекс на каждый JSON ключ), но тем не менее этого  достаточно для широкого круга задач. И начиная с Django 1.9 эти функции доступны из коробки.

В MongoDB аналога оператору `@>` нет. Можно изменить структуру данных и делать аналогичные запросы по группе полей, используя один индекс. Но это менее эффективно, чем в PostgreSQL. Ведь индекс будет применяться только к первому ключу, а не ко всем.
Зато MongoDB поддерживает гораздо больше операций при фильтрации по _одному_ _любому_ ключу, используя один индекс.

Пока мне очень нравится JSON в PostgreSQL, оно здорово облегчает решение многих задач. При этом мы сохраняем возможности SQL: транзакции и join'ы, которых нет в MongoDB. И теперь это поддерживается Django ORM.


### Полезные ссылки

- [Django JSONField docs](https://docs.djangoproject.com/en/dev/ref/contrib/postgres/fields/#jsonfield)
- [PostgreSQL JSON type docs](http://www.postgresql.org/docs/9.4/static/datatype-json.html)
- [PostgreSQL JSON functions and operations docs](http://www.postgresql.org/docs/9.4/static/functions-json.html)
- [Christophe Pettus - PostgreSQL Proficiency for Python People - PyCon 2015 (video)](http://www.youtube.com/watch?v=78A2gJBgL9g)
- [PostgreSQL and JSON: 2015. Christophe Pettus. PGConf US 2015 (slides)](http://thebuild.com/presentations/json2015-pgconfus.pdf)
- [Asya Kamsky, Yandex 2014 MongoDB meetup](https://events.yandex.ru/lib/talks/1707/)
