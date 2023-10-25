---
layout: post
title:  "Django queryset.count cache"
date:   2013-07-11 18:19:43 +0000
categories: database django sql
redirect_from:
  - /2013/django-querysetcount-cache/
  - /blog/2013/07/11/django-querysetcount-cache.html
---

[![Django queryset.count cache](/assets/images/posts/2013-07-11-django-querysetcount-cache/to-count-22117_small.jpeg "Django queryset.count cache")]({{ site.baseurl }}{{ page.url }})

Once I mentioned, that my django application makes several similiar queries like `SELECT COUNT(*) ...`. As it turns out (for me it was surprise), `queryset.count()` has not obvious cache. But let me start the story from the beginning (and sorry for my english :) ).

<!--more-->

As it is known, django's `queryset` is lazy and have cache.

Lets say we have such model:

```python
class Item(models.Model):
    name = models.CharField(max_length=50)
```

When some django query is declared there is no database attempt (thats why it is called "lazy"):

```python
items = Item.objects.all()
```

The attempt is made when we actually access elements from queryset, for example in cycle:

```python
for item in items:
     print item.name
```

During executing line `for item in items:` sql query was performed:

```python
SELECT "main_item"."id", "main_item"."name" FROM "main_item";
```

At next access to elements from queryset, database attempt will not occur, because all elements were touched and consequently put into cache. So, this code will hit the DB only once:

```python
for item in items: # hit the database
     print item.name
for item in items: # cache
     print item.name
```

Nevertheless there are some cases, when database can be touched again. To not put very much information in a single post, refer to documentation: [https://docs.djangoproject.com/en/dev/topics/db/queries/#caching-and-querysets](https://docs.djangoproject.com/en/dev/topics/db/queries/#caching-and-querysets).

### Now directly about count

Keeping in mind, that queryset has cache, i thought, that .count() will also be cached. But it is not (not always precisely). If count() method was called before queryset is put in cache, then database will be touched every time count() is called:

```python
items = Item.objects.all() # not hit DB
items.count() # hit DB
items.count() # hit DB
items.count() # hit DB
for item in items: # hit DB and put into cache
     print item.name
```

Нowever, if source queryset is cached, then count will not touch the database:

```python
items = Item.objects.all() # no DB hit
for item in items: # hit DB and put to cache
     print item.name
items.count() # cache
items.count() # cache
items.count() # cache
```

All this concerns django templates too. The code, that made identical queries like `SELECT COUNT(*) ...` has several checks like:

```python
{% raw %}{% if items.count %}{% endraw %}
```

and also some count output:

```python
{% raw %}{{ items.count }}{% endraw %}
```

Before these lines the queryset elements were not being accessed. As a result, each mentioned line create database query.

Again, if such cycle was before:

```python
{% raw %}{% for item in items %}
    {{item.name}}
{% endfor %}{% endraw %}
```

then `{% raw %}{{ items.count }}{% endraw %}` doesn't hit the DB.

**Approaches to exclude redundant database calls.**

1. If we know, that we'll need to access all elements from query set, it is ok to use `len`.

     Python code:

     ```python
     len(items) # DB
     len(items) # cache
     for item in items: # cache
         # ...
     ```

     and reversed, that is also acceptable:

     ```python
     for item in items: # DB
         # ...
     len(items) # cache
     len(items) # cache
     ```

     Django template:

     ```python
     {% raw %}{{ items|length }} # DB
     {{ items|length }} # cache
     {% if items|length %} # cache
     {% for item in items %} # cache{% endraw %}
     ```

     and reversed:

     ```python
     {% raw %}{% for item in items %} # DB
     {{ items|length }} # cache
     {{ items|length }} # cache
     {% if items|length %} # cache{% endraw %}
     ```


2. If it is needed to know only count of elements, or source queryset for count is different to queryset, that will be used to access elements, then we shall use count(). But it is better, if it will be called only once.

     If count is needed more than one time, then instead of this:

     ```python
     {% raw %}{{ items.count }}
     {{ items.count }}{% endraw %}
     ```

     we can create additional variable in template context (in view, that renders this template):

     ```python
     # views.py
     context['items_count'] = items.count()

     # template
     {% raw %}{{ items_count }}
     {{ items_count }}{% endraw %}
     ```

     or we can use `{% raw %}{% with items.count as items_count %}{% endraw %}` and not declare any additional variable in context:

     ```python
     # template
     {% raw %}{% with items.count as items_count %}
          {{ items_count }}
          {{ items_count }}
     {% endwith %}{% endraw %}
     ```

Of course, everywere in this post word "cache" means queryset internal cache, and not [caching](https://docs.djangoproject.com/en/dev/topics/cache/).
