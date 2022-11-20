---
layout: post
title:  "Кеширование queryset.count в django"
date:   2013-07-11 18:19:43 +0000
categories: database django sql
redirect_from:
  - /2013/django-querysetcount-cache/
---

[![Кеширование queryset.count в django](/assets/images/posts/2013-07-11-django-querysetcount-cache/to-count-22117_small.jpeg "Кеширование queryset.count в django")]({{ site.baseurl }}{{ page.url }})

Как-то обнаружил, что у меня идут несколько одинаковых запросов вида `SELECT COUNT(*) ...`. Оказалось (да, для меня это было новостью :) ), что метод `queryset.count()` в джанго кешируется по особому. Но лучше начать рассказ издалека.

<!--more-->

Как известно, объекты `queryset` у ORM django являются "ленивыми", а так же кешируются.

Т.е., преподолжим у нас такая модель:

```python
class Item(models.Model):
    name = models.CharField(max_length=50)
```

Тогда при создании запроса фактически обращения к БД не происходит (отсюда название lazy - "ленивый"):

```python
items = Item.objects.all()
```

Оно происходит, когда мы непосредственно обращаемся к объектам из запроса, например в цикле:

```python
for item in items:
     print item.name
```

При исполнении инструкции `for item in items:` был такой запрос к БД:

```python
SELECT "main_item"."id", "main_item"."name" FROM "main_item";
```

При следующем обращении к объектам уже запроса к БД не будет, т.к. все объекты уже были "потроганы" и они попали в кэш. Т.е. этот код сделает только одно обращение к БД:

```python
for item in items: # hit the database
     print item.name
for item in items: # cache
     print item.name
```

Тем не менее, есть некоторые нюансы, когда может произойти второй запрос к БД. Не буду дублировать документацию, чтобы не загромождать статью. Можно почитать здесь: [https://docs.djangoproject.com/en/dev/topics/db/queries/#caching-and-querysets](https://docs.djangoproject.com/en/dev/topics/db/queries/#caching-and-querysets).

### Теперь непосредственно про count

Зная, что queryset кешируется, мне казалось, что и .count() тоже кешируется. Но нет (точнее не всегда). Если вызываем метод count() до того, как исходный queryset попал в кеш, будет обращение к БД при каждом вызове count (данное обращение не ленивое, ведь count() возвращает число, а не другой queryset, как это делают all, filter, exclude):

```python
items = Item.objects.all() # not hit DB
items.count() # hit DB
items.count() # hit DB
items.count() # hit DB
for item in items: # hit DB and put into cache
     print item.name
```

Однако, если исходный queryset попал в кеш, то count уже не будет трогать БД:

```python
items = Item.objects.all() # no DB hit
for item in items: # hit DB and put to cache
     print item.name
items.count() # cache
items.count() # cache
items.count() # cache
```

Соответственно все это относится и к шаблонам django. В коде, который делал несколько одинаковых запросов `SELECT COUNT(*) ...`, как раз были проверки вида:

```python
{% raw %}{% if items.count %}{% endraw %}
```

и просто вывод количества:

```python
{% raw %}{{ items.count }}{% endraw %}
```

При этом до этих строк не было обращения к самим объектам items. В итоге на каждой из этих строк шел запрос к БД.

Опять же, если до этого где-то был цикл, например такой:

```python
{% raw %}{% for item in items %}
    {{item.name}}
{% endfor %}{% endraw %}
```

то `{% raw %}{{ items.count }}{% endraw %}` уже не обращался к БД.

**Итак, варианты для избежания лишних запросов.**

1. Если мы знаем, что где-то дальше будет перебор всех элементов из queryset, то вполне уместно использовать `len`.

    Python код:

    ```python
    len(items) # DB
    len(items) # cache
    for item in items: # cache
        # ...
    ```

    или наоборот, что тоже верно:

    ```python
    for item in items: # DB
        # ...
    len(items) # cache
    len(items) # cache
    ```

    Шаблон django:

    ```python
    {% raw %}{{ items|length }} # DB
    {{ items|length }} # cache
    {% if items|length %} # cache
    {% for item in items %} # cache{% endraw %}
    ```

    или наоборот:

    ```python
    {% raw %}{% for item in items %} # DB
    {{ items|length }} # cache
    {{ items|length }} # cache
    {% if items|length %} # cache{% endraw %}
    ```


2. Если нужно только подсчитать количество, либо queryset, для которого нужно количество не совпадает с тем, который будет использоваться для доступа к элементам, то надо использовать count(). Но вызывать его лучше только единожды

    Если в шаблоне нужно обратиться к count более одного раза, то вместо этого:

    ```python
    {% raw %}{{ items.count }}
    {{ items.count }}{% endraw %}
    ```

    надо либо во view, который генерит этот шаблон, добавить переменную items_count в контекст и в шаблоне использовать ее:

    ```python
    # views.py
    context['items_count'] = items.count()

    # template
    {% raw %}{{ items_count }}
    {{ items_count }}{% endraw %}
    ```

    либо можно использовать `{% raw %}{% with items.count as items_count %}{% endraw %}` (не добавляя в контекст новых переменных из views.py):

    ```python
    # template
    {% raw %}{% with items.count as items_count %}
         {{ items_count }}
         {{ items_count }}
    {% endwith %}{% endraw %}
    ```

Конечно, в этой статье под словом "кеш" имеется в виду внутренний кеш queryset. Он никак не связан с [кешированием](https://docs.djangoproject.com/en/dev/topics/cache/).
