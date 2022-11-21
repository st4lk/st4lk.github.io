---
layout: post
title:  "Вложенные SQL запросы в Django"
date:   2014-09-09 18:19:43 +0000
categories: database django sql
redirect_from:
  - /2014/nested-sql-queries-django/
---

[![Вложенные SQL запросы в Django](/assets/images/posts/2014-09-09-nested-sql-queries-django/Kenguru-origami-za-shemoj-Stephen-Weiss.jpeg "Вложенные SQL запросы в Django")]({{ site.baseurl }}{{ page.url }})

Вы знали, что Django ORM умеет делать [вложенные SQL запросы](https://docs.djangoproject.com/en/dev/ref/models/querysets/#in)? К своему стыду я узнал это не так давно.

<!--more-->

Допустим, у нас есть такие модели питомника (Nursery) и питомца (Pet):

```python
class Nursery(models.Model):
    title = models.CharField(max_length=50)

class Pet(models.Model):
    name = models.CharField(max_length=50)
    nursery = models.ForeignKey(Nursery, related_name='pets')
```

Нам нужно получить всех питомцев (Pet), которые находятся в заданных питомниках (Nursery). Например в питомниках, title который начинается с "Moscow":

```python
nurseries = Nursery.objects.filter(title__startswith="Moscow")
Pet.objects.filter(nursery__in=nurseries)
```

Эти строчки сделают лишь один запрос к базе данных, в котором будет вложенный запрос :

```sql
SELECT "users_pet"."id", "users_pet"."name", "users_pet"."nursery_id" FROM "users_pet" WHERE "users_pet"."nursery_id" IN (SELECT "users_nursery"."id" FROM "users_nursery" WHERE "users_nursery"."title" LIKE Moscow%)
```

Однако, следует иметь в виду, что хотя выполняется один запрос к БД, это не всегда означает лучшую производительность. Тут все зависит от выбранной базы данных. Например, как советуют в [документации django](https://docs.djangoproject.com/en/dev/ref/models/querysets/#nested-queries-performance), в случае MySQL более эффективно выполнить два запроса вместо одного, т.к. эта БД не всегда хорошо оптимизирует вложенные запросы.

Т.е. для MySQL такой код будет эффективнее (судя по докам django):

```python
nurseries = Nursery.objects.filter(title__startswith="Moscow").values_list('pk', flat=True)
Pet.objects.filter(nursery__in=list(nurseries))
```

несмотря на то, что выполнится два запроса:

```sql
SELECT "users_nursery"."id" FROM "users_nursery" WHERE "users_nursery"."title" LIKE Moscow%
SELECT "users_pet"."id", "users_pet"."name", "users_pet"."nursery_id" FROM "users_pet" WHERE "users_pet"."nursery_id" IN (1, 2)
```
