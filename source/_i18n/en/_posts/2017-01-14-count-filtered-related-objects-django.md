---
layout: post
title:  "Trap in counting related objects in Django"
date:   2017-01-14 18:19:43 +0000
categories: database django sql
redirect_from:
  - /2017/count-filtered-related-objects-django/
  - /blog/2017/01/14/count-filtered-related-objects-django.html
---

[![Trap in counting related objects in Django](https://img-fotki.yandex.ru/get/172931/85893628.c6b/0_1f68eb_c4171bf7_L.png
 "Trap in counting related objects in Django")]({{ site.baseurl }}{{ page.url }})

Task: for every object count number of related objects satisfying some conditions.

<!--more-->

Example:

    class Category(models.Model):
        title = models.CharField(max_length=50)

    class Article(models.Model):
        title = models.CharField(max_length=50)
        category = models.ForeignKey(Category)
        approved_at = models.DateTimeField(blank=True, null=True)

Pay attention at field `Article.approved_at`, it contains article approval time and it can be null.

Create test data:

    from django.utils import timezone

    c1 = Category.objects.create(title='c1')
    c2 = Category.objects.create(title='c2')

    a1 = Article.objects.create(category=c1, title='a1')
    a2 = Article.objects.create(category=c1, title='a2', approved_at=timezone.now())

So we have two categories. The first one has one approved and one not approved article. The second category doesn't have any article.

Let's begin with counting all articles for each category:

    from django.db.models import Count
    
    >>> Category.objects.annotate(
    ...     article_count=Count('article')
    ... ).values('title', 'article_count')

    <QuerySet [{'article_count': 2, 'title': u'c1'}, {'article_count': 0, 'title': u'c2'}]>

Django ORM built following expected SQL query:

    SELECT "main_category"."title", COUNT("main_article"."id") AS "article_count"
        FROM "main_category"
        LEFT OUTER JOIN "main_article" ON ("main_category"."id" = "main_article"."category_id")
        GROUP BY "main_category"."id", "main_category"."title";

Ok, now we want to count only approved articles. Using SQL language, we can just update JOIN part:

    SELECT "main_category"."title", COUNT("main_article"."id") AS "article_count"
        FROM "main_category"
        LEFT OUTER JOIN "main_article" 
            ON ("main_category"."id" = "main_article"."category_id" AND
                "main_article"."approved_at" IS NOT NULL)
        GROUP BY "main_category"."id", "main_category"."title";

Unfortunately, Django ORM doesn't allow to apply any filter for `Count` (at least in v1.10). But starting from v1.8 we have [conditional expressions](https://docs.djangoproject.com/en/dev/ref/models/conditional-expressions/), so let's use it:

    from django.db.models import Count, Case, When

    >>> Category.objects.annotate(
    ...     article_count=Count(
    ...         Case(When(article__approved_at__isnull=False, then=1))
    ...     )
    ... ).values('title', 'article_count')

    <QuerySet [{'article_count': 1, 'title': u'c1'}, {'article_count': 0, 'title': u'c2'}]>

The returned values are valid. Corresponding SQL query:

    SELECT "main_category"."title", COUNT(
        CASE WHEN "main_article"."approved_at" IS NOT NULL THEN 1 ELSE NULL END
    ) AS "article_count"
    FROM "main_category"
    LEFT OUTER JOIN "main_article" ON ("main_category"."id" = "main_article"."category_id")
    GROUP BY "main_category"."id", "main_category"."title";

## The Trap

Here is an interesting question, how we can count number of *not approved* articles?

The first thought that comes to the mind is to change `False` to `True` in the query:

    >>> Category.objects.annotate(
    ...     article_count=Count(
    ...         Case(When(article__approved_at__isnull=True, then=1))
    ...     )
    ... ).values('title', 'article_count')

But query returns not valid values:

    <QuerySet [{'article_count': 1, 'title': u'c1'}, {'article_count': 1, 'title': u'c2'}]>

The second category has mysterious unapproved article.

Check the SQL:

    SELECT "main_category"."title", COUNT(
        CASE WHEN "main_article"."approved_at" IS NULL THEN 1 ELSE NULL END
    ) AS "article_count"
    FROM "main_category"
    LEFT OUTER JOIN "main_article" ON ("main_category"."id" = "main_article"."category_id")
    GROUP BY "main_category"."id", "main_category"."title";

The condition

    CASE WHEN "main_article"."approved_at" IS NULL THEN 1

will be true even if category doesn't have any article at all!

One approach to fix is the following:

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

## The moral of the story

When condition like `IS NULL` happens, double check every edge case!


