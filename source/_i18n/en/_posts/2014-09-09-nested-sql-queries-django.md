---
layout: post
title:  "Nested SQL queries in Django"
date:   2014-09-09 18:19:43 +0000
categories: database django sql
redirect_from:
  - /2014/nested-sql-queries-django/
---

[![Nested SQL queries in Django](/assets/images/posts/2014-09-09-nested-sql-queries-django/Kenguru-origami-za-shemoj-Stephen-Weiss.jpeg "Nested SQL queries in Django")]({{ site.baseurl }}{{ page.url }})

Did you know, that Django ORM can do [nested SQL queries](https://docs.djangoproject.com/en/dev/ref/models/querysets/#in)? Shame on me, but i've found it not so long ago.

<!--more-->

So, lets say we have such models of Nursery and Pet:

```python
class Nursery(models.Model):
    title = models.CharField(max_length=50)

class Pet(models.Model):
    name = models.CharField(max_length=50)
    nursery = models.ForeignKey(Nursery, related_name='pets')
```

We need to get all pets, that are placed in given nurseries. For example, in nurseries with title starts with "Moscow":

```python
nurseries = Nursery.objects.filter(title__startswith="Moscow")
Pet.objects.filter(nursery__in=nurseries)
```

That code will do only one SQL query, that will have nested subquery:

```sql
SELECT "users_pet"."id", "users_pet"."name", "users_pet"."nursery_id" FROM "users_pet" WHERE "users_pet"."nursery_id" IN (SELECT "users_nursery"."id" FROM "users_nursery" WHERE "users_nursery"."title" LIKE Moscow%)
```

But, keep in mind, that in spite of only one query is executed, it is not always means better performance. It depends on exact database, that is used. For example, as it written in [django documentation](https://docs.djangoproject.com/en/dev/ref/models/querysets/#nested-queries-performance), in case of MySQL two queries will be more effective than one with a nested subquery. Because MySQL don’t optimize nested queries very well.

So, according to django docs, such code will bring us better performance:

```python
nurseries = Nursery.objects.filter(title__startswith="Moscow").values_list('pk', flat=True)
Pet.objects.filter(nursery__in=list(nurseries))
```

in spite of two queries being executed than one:

```sql
SELECT "users_nursery"."id" FROM "users_nursery" WHERE "users_nursery"."title" LIKE Moscow%
SELECT "users_pet"."id", "users_pet"."name", "users_pet"."nursery_id" FROM "users_pet" WHERE "users_pet"."nursery_id" IN (1, 2)
```
