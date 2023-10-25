---
layout: post
title:  "Ловушка при подсчете связанных объектов в Django"
date:   2017-01-14 18:19:43 +0000
categories: database django sql
redirect_from:
  - /2017/count-filtered-related-objects-django/
  - /blog/2017/01/14/count-filtered-related-objects-django.html
---

[![Ловушка при подсчете связанных объектов в Django](https://img-fotki.yandex.ru/get/172931/85893628.c6b/0_1f68eb_c4171bf7_L.png
 "Ловушка при подсчете связанных объектов в Django")]({{ site.baseurl }}{{ page.url }})

Задача: для каждого объекта подсчитать количество связанных объектов, удовлетворяющих определенному условию.

<!--more-->

Пример:

    class Category(models.Model):
        title = models.CharField(max_length=50)

    class Article(models.Model):
        title = models.CharField(max_length=50)
        category = models.ForeignKey(Category)
        approved_at = models.DateTimeField(blank=True, null=True)

Видим, что поле `Article.approved_at` хранит время одобрения статьи, причем оно может быть пустым (т.е. `NULL` в базе данных).

Создадим тестовые данные:

    from django.utils import timezone

    c1 = Category.objects.create(title='c1')
    c2 = Category.objects.create(title='c2')

    a1 = Article.objects.create(category=c1, title='a1')
    a2 = Article.objects.create(category=c1, title='a2', approved_at=timezone.now())

Итого у нас две категории. У первой есть одна одобренная статья и одна неодобренная. У второй категории статей нет.

Для начала подсчитаем, сколько вообще статей в каждой категории:

    from django.db.models import Count
    
    >>> Category.objects.annotate(
    ...     article_count=Count('article')
    ... ).values('title', 'article_count')

    <QuerySet [{'article_count': 2, 'title': u'c1'}, {'article_count': 0, 'title': u'c2'}]>

SQL запрос, который построила ORM Django, вполне ожидаем:

    SELECT "main_category"."title", COUNT("main_article"."id") AS "article_count"
        FROM "main_category"
        LEFT OUTER JOIN "main_article" ON ("main_category"."id" = "main_article"."category_id")
        GROUP BY "main_category"."id", "main_category"."title";

Ок, давайте подсчитаем только одобренные статьи. Если бы мы писали на SQL, то можно было бы просто добавить еще одно условие для JOIN:

    SELECT "main_category"."title", COUNT("main_article"."id") AS "article_count"
        FROM "main_category"
        LEFT OUTER JOIN "main_article" 
            ON ("main_category"."id" = "main_article"."category_id" AND
                "main_article"."approved_at" IS NOT NULL)
        GROUP BY "main_category"."id", "main_category"."title";

К сожалению, Django ORM не поддерживает фильтры для `Count`  (по крайне мере v1.10). Но начиная с v1.8 у нас есть [условные выражения](https://docs.djangoproject.com/en/dev/ref/models/conditional-expressions/) и с помощью них можно выполнить такой трюк:

    from django.db.models import Count, Case, When

    >>> Category.objects.annotate(
    ...     article_count=Count(
    ...         Case(When(article__approved_at__isnull=False, then=1))
    ...     )
    ... ).values('title', 'article_count')

    <QuerySet [{'article_count': 1, 'title': u'c1'}, {'article_count': 0, 'title': u'c2'}]>

Данные верные. SQL запрос получился таким:

    SELECT "main_category"."title", COUNT(
        CASE WHEN "main_article"."approved_at" IS NOT NULL THEN 1 ELSE NULL END
    ) AS "article_count"
    FROM "main_category"
    LEFT OUTER JOIN "main_article" ON ("main_category"."id" = "main_article"."category_id")
    GROUP BY "main_category"."id", "main_category"."title";

## Ловушка

Теперь интересный вопрос, как нам подсчитать количество *неодобренных* статей?

Первое, что приходит в голову, это просто поменять `False` на `True` в запросе:

    >>> Category.objects.annotate(
    ...     article_count=Count(
    ...         Case(When(article__approved_at__isnull=True, then=1))
    ...     )
    ... ).values('title', 'article_count')

Вот только ответ получим не совсем правильный:

    <QuerySet [{'article_count': 1, 'title': u'c1'}, {'article_count': 1, 'title': u'c2'}]>

У второй категории откуда-то нашлась неодобренная статья.

Смотрим SQL:

    SELECT "main_category"."title", COUNT(
        CASE WHEN "main_article"."approved_at" IS NULL THEN 1 ELSE NULL END
    ) AS "article_count"
    FROM "main_category"
    LEFT OUTER JOIN "main_article" ON ("main_category"."id" = "main_article"."category_id")
    GROUP BY "main_category"."id", "main_category"."title";

Условие

    CASE WHEN "main_article"."approved_at" IS NULL THEN 1

срабатывает даже тогда, когда у категории вообще нет статьи.

В нашем случае запрос можно исправить так:

    >>> Category.objects.annotate(
    ...     article_count=Count(
    ...         Case(
    ...             When(
    ...                 article__id__isnull=False,
    ...                 article__approved_at__isnull=True,
    ...                 then=1
    ...             )
    ...         )
    ...     )
    ... ).values('title', 'article_count')

    <QuerySet [{'article_count': 1, 'title': u'c1'}, {'article_count': 0, 'title': u'c2'}]>

## Мораль

При проверках вида `IS NULL` нужно быть особенно осторожным и прикидывать возможные побочные эффекты!


