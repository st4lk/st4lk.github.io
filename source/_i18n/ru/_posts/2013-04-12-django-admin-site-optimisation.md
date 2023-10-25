---
layout: post
title:  "Оптимизация админки django"
date:   2013-04-12 18:19:43 +0000
categories: django database sql
redirect_from:
  - /2013/django-admin-site-optimisation/
  - /blog/2013/04/12/django-admin-site-optimisation.html
---

[![Django admin site optimisation](/assets/images/posts/2013-04-12-django-admin-site-optimisation/django-admin-performance.png "Django admin site optimisation")]({{ site.baseurl }}{{ page.url }})

Как известно, чем меньше запросов к базе данных делает сайт, тем лучше производительность. Обычно админка - часть сайта с меньшим трафиком, но все же хорошо, если от туда не идут лишние запросы. Это и приятней в пользовании, т.к. страница отдается быстрее, и все-таки разгружает сервер.

В этом посте я рассмотрю некоторые способы уменьшения количества запросов из админки к БД при использовании `__unicode__`, содержащего поля связанного объекта (ForeignKey). Думаю, глядя на примеры станет понятнее.

<!--more-->

### 1. `__unicode__` at admin change form page

Рассмотрим пример, в котором есть модели станции метро (SubwayStation), линии метро (SubwayLine), города (City). Линия - это ForeignKey для станции, а City - ForeignKey для линии.

`models.py`:

```python
from django.db import models


class City(models.Model):
    name = models.CharField(max_length=50)

    def __unicode__(self):
        return self.name


class SubwayLine(models.Model):
    name = models.CharField(max_length=50)
    city = models.ForeignKey(City, related_name='lines')

    def __unicode__(self):
        return u"{0}, {1}".format(self.city, self.name)


class SubwayStation(models.Model):
    name = models.CharField(max_length=50)
    line = models.ForeignKey(SubwayLine, related_name='stations')

    def __unicode__(self):
        return self.name
```

`admin.py`:

```python
from django.contrib import admin
from .models import SubwayLine, SubwayStation, City


class SubwayLineAdmin(admin.ModelAdmin):
    list_display = 'name',


class SubwayStationAdmin(admin.ModelAdmin):
    list_display = 'name', 'line'


class CityAdmin(admin.ModelAdmin):
    list_display = 'name',


admin.site.register(SubwayLine, SubwayLineAdmin)
admin.site.register(SubwayStation, SubwayStationAdmin)
admin.site.register(City, CityAdmin)
```

Зайдем на страницу изменения станции

![SubwayStation change form page](/assets/images/posts/2013-04-12-django-admin-site-optimisation/station_change.png "SubwayStation change form page")

Как видим, `__unicode__` для линии состоит из двух полей: поля связанного объекта City.name и поля SubwayLine.name.

Посмотрим теперь, какие запросы были к БД (запросы к таблицам django_session, auth_user, django_content_type в расчет не берем):

```sql
SELECT "main_subwaystation"."id", "main_subwaystation"."name", "main_subwaystation"."line_id" FROM "main_subwaystation" WHERE "main_subwaystation"."id" = 1 ;
SELECT "main_subwayline"."id", "main_subwayline"."name", "main_subwayline"."city_id" FROM "main_subwayline";
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 2 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 2 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 2 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 2 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 2 ;
```

Идут такие запросы:

- первый - получить запись станции
- второй - получить все варианты линий
- остальные - получить для каждой линии имя города

Получается, что количество запросов = 2 + количество линий. Это много.

#### Чтобы исправить ситуацию есть два варианта

- Использовать [select_related](https://docs.djangoproject.com/en/dev/ref/models/querysets/#select-related) в запросе

    Для этого переопределим форму админки для SubwayStation:

    `admin.py`:

    ```python
    from django.contrib import admin
    from django import forms
    from .models import SubwayLine, SubwayStation, City


    class SubwayLineAdmin(admin.ModelAdmin):
        list_display = 'name',


    class SubwayStationForm(forms.ModelForm):

        def __init__(self, *args, **kwargs):
            super(SubwayStationForm, self).__init__(*args, **kwargs)
            self.fields['line'].queryset = SubwayLine.objects.all()\
                .select_related('city')

        class Meta:
            model = SubwayStation


    class SubwayStationAdmin(admin.ModelAdmin):
        list_display = 'name',
        form = SubwayStationForm


    class CityAdmin(admin.ModelAdmin):
        list_display = 'name',


    admin.site.register(SubwayLine, SubwayLineAdmin)
    admin.site.register(SubwayStation, SubwayStationAdmin)
    admin.site.register(City, CityAdmin)
    ```

    И теперь при отображении страницы станции осталось только два запроса (благодаря INNER JOIN):

    ```sql
    SELECT "main_subwaystation"."id", "main_subwaystation"."name", "main_subwaystation"."line_id" FROM "main_subwaystation" WHERE "main_subwaystation"."id" = 1 ;
    SELECT "main_subwayline"."id", "main_subwayline"."name", "main_subwayline"."city_id", "main_city"."id", "main_city"."name" FROM "main_subwayline" INNER JOIN "main_city" ON ("main_subwayline"."city_id" = "main_city"."id");
    ```

- Использовать [raw_id_fields](https://docs.djangoproject.com/en/dev/ref/contrib/admin/#django.contrib.admin.ModelAdmin.raw_id_fields) (полезно, когда записей так много, что неудобно и дорого их выводить в выпадающем списке)

    Задаем raw_id_fields у SubwayStationAdmin:

    `admin.py`:

    ```python
    class SubwayStationAdmin(admin.ModelAdmin):
        list_display = 'name',
        raw_id_fields = 'line',
    ```

    Страница теперь выглядит так:

    ![SubwayStation change form page with line as raw_id_field](/assets/images/posts/2013-04-12-django-admin-site-optimisation/station_change_rawid.png "SubwayStation change form page with line as raw_id_field")

    Смотрим запросы:

    ```sql
    SELECT "main_subwaystation"."id", "main_subwaystation"."name", "main_subwaystation"."line_id" FROM "main_subwaystation" WHERE "main_subwaystation"."id" = 1 ;
    SELECT "main_subwayline"."id", "main_subwayline"."name", "main_subwayline"."city_id" FROM "main_subwayline" WHERE "main_subwayline"."id" = 1 ;
    SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;1,)
    ```

    Три запроса, где третий - это запрос города для отображения `__unicode__` линии. Хорошо. При желании можно пойти еще дальше и избавиться от этого последнего запроса. Для этого придется переопределить виджет ForeignKeyRawIdWidget:

    `admin.py`:

    ```python
    from django.contrib import admin
    from django.contrib.admin.widgets import ForeignKeyRawIdWidget
    from django.contrib.admin.sites import site
    from django.utils.text import Truncator
    from django.utils.html import escape
    from django import forms
    from .models import SubwayLine, SubwayStation, City


    class SubwayLineAdmin(admin.ModelAdmin):
        list_display = 'name',


    class StationForeignKeyRawIdWidget(ForeignKeyRawIdWidget):
        def label_for_value(self, value):
            key = self.rel.get_related_field().name
            try:
                obj = self.rel.to._default_manager.select_related('city').using(self.db).get(**{key: value})
                return '&nbsp;<strong>%s</strong>' % escape(Truncator(obj).words(14, truncate='...'))
            except (ValueError, self.rel.to.DoesNotExist):
                return ''


    class SubwayStationForm(forms.ModelForm):

        def __init__(self, *args, **kwargs):
            super(SubwayStationForm, self).__init__(*args, **kwargs)
            self.fields['line'].widget = StationForeignKeyRawIdWidget(
                SubwayStation._meta.get_field("line").rel, site)

        class Meta:
            model = SubwayStation


    class SubwayStationAdmin(admin.ModelAdmin):
        list_display = 'name',
        raw_id_fields = 'line',
        form = SubwayStationForm


    class CityAdmin(admin.ModelAdmin):
        list_display = 'name',


    admin.site.register(SubwayLine, SubwayLineAdmin)
    admin.site.register(SubwayStation, SubwayStationAdmin)
    admin.site.register(City, CityAdmin)
    ```

    И запросов осталось только два:

    ```sql
    SELECT "main_subwaystation"."id", "main_subwaystation"."name", "main_subwaystation"."line_id" FROM "main_subwaystation" WHERE "main_subwaystation"."id" = 1 ;
    SELECT "main_subwayline"."id", "main_subwayline"."name", "main_subwayline"."city_id", "main_city"."id", "main_city"."name" FROM "main_subwayline" INNER JOIN "main_city" ON ("main_subwayline"."city_id" = "main_city"."id") WHERE "main_subwayline"."id" = 1 ;
    ```

    Приведенный вариант с переопределением ForeignKeyRawIdWidget будет работать на django 1.4, 1.5. Для более ранних версий метод `label_for_value` отличается, так что его нужно скопировать из класса ForeignKeyRawIdWidget модуля django/contrib/admin/widgets.py и добавить к нему ``.select_related('city')`.

### 2. `__unicode__` в inline формах

Показанные выше методы можно применять и в inline формах. Допустим у нас появилась модель района (District), на которую ссылается станция по ForeignKey:

`models.py`:

```python
# ...

class District(models.Model):
    name = models.CharField(max_length=50)
    city = models.ForeignKey(City, related_name='districts')

    def __unicode__(self):
        return u"{0}, {1}".format(self.city, self.name)


class SubwayStation(models.Model):
    name = models.CharField(max_length=50)
    line = models.ForeignKey(SubwayLine, related_name='stations')
    district = models.ForeignKey(District, related_name='stations')

    def __unicode__(self):
        return self.name

# ...
```

Как видим, `__unicode__` у District включает поле связанной модели City. Теперь добавим станции как inline к линии метро:

`admin.py`:

```python
# ...

class SubwayStationInline(admin.TabularInline):
    model = SubwayStation
    extra = 0


class SubwayLineAdmin(admin.ModelAdmin):
    list_display = 'name',
    inlines = SubwayStationInline,

# ...
```

Откроем страницу редактирования линии

![SubwayLine change form page with SubwayStation inline](/assets/images/posts/2013-04-12-django-admin-site-optimisation/line_change_inline.png "SubwayLine change form page with SubwayStation inline")

И посмотрим, какие запросы к БД были при отображении страницы (для простоты я сделал только две станции у данной линии):

```sql
SELECT "main_subwayline"."id", "main_subwayline"."name", "main_subwayline"."city_id" FROM "main_subwayline" WHERE "main_subwayline"."id" = 1 ;
SELECT "main_subwaystation"."id", "main_subwaystation"."name", "main_subwaystation"."line_id", "main_subwaystation"."district_id" FROM "main_subwaystation" WHERE "main_subwaystation"."line_id" = 1  ORDER BY "main_subwaystation"."id" ASC;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;1,)
SELECT "main_city"."id", "main_city"."name" FROM "main_city";
SELECT "main_district"."id", "main_district"."name", "main_district"."city_id" FROM "main_district";
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;1,)
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;1,)
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;1,)
SELECT "main_district"."id", "main_district"."name", "main_district"."city_id" FROM "main_district";
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;1,)
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;1,)
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;1,)
SELECT "main_district"."id", "main_district"."name", "main_district"."city_id" FROM "main_district";
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;1,)
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;1,)
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;1,)
```

Получается, что на каждую вложенную станцию идет запрос на получение всех районов + города на каждый район. Тут можно избавиться от дополнительных запросов для получения города района, сделав `select_related('city')` в форме для Inline модели:

`admin.py`:

```python
# ...

from django import forms
from .models import SubwayLine, SubwayStation, City, District


class SubwayStationForm(forms.ModelForm):

    def __init__(self, *args, **kwargs):
        super(SubwayStationForm, self).__init__(*args, **kwargs)
        self.fields['district'].queryset = District.objects.all()\
            .select_related('city')

    class Meta:
        model = SubwayStation


class SubwayStationInline(admin.TabularInline):
    model = SubwayStation
    form = SubwayStationForm
    extra = 0


class SubwayLineAdmin(admin.ModelAdmin):
    list_display = 'name',
    inlines = SubwayStationInline,

# ...
```

Теперь уже нет отдельных запросов городов:

```sql
SELECT "main_subwayline"."id", "main_subwayline"."name", "main_subwayline"."city_id" FROM "main_subwayline" WHERE "main_subwayline"."id" = 1 ;
SELECT "main_subwaystation"."id", "main_subwaystation"."name", "main_subwaystation"."line_id", "main_subwaystation"."district_id" FROM "main_subwaystation" WHERE "main_subwaystation"."line_id" = 1  ORDER BY "main_subwaystation"."id" ASC;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;1,)
SELECT "main_city"."id", "main_city"."name" FROM "main_city";
SELECT "main_district"."id", "main_district"."name", "main_district"."city_id", "main_city"."id", "main_city"."name" FROM "main_district" INNER JOIN "main_city" ON ("main_district"."city_id" = "main_city"."id");
SELECT "main_district"."id", "main_district"."name", "main_district"."city_id", "main_city"."id", "main_city"."name" FROM "main_district" INNER JOIN "main_city" ON ("main_district"."city_id" = "main_city"."id");
SELECT "main_district"."id", "main_district"."name", "main_district"."city_id", "main_city"."id", "main_city"."name" FROM "main_district" INNER JOIN "main_city" ON ("main_district"."city_id" = "main_city"."id");
```

### 3. `__unicode__` на странице списка объектов (change list page)

Рассмотрим страницу списка станций. Напомню код модели и админки:

`models.py`:

```python
# ...

class SubwayLine(models.Model):
    name = models.CharField(max_length=50)
    city = models.ForeignKey(City, related_name='lines')

    def __unicode__(self):
        return u"{0}, {1}".format(self.city, self.name)


class SubwayStation(models.Model):
    name = models.CharField(max_length=50)
    line = models.ForeignKey(SubwayLine, related_name='stations')

    def __unicode__(self):
        return self.name

# ...
```

`admin.py`:

```python
# ...

class SubwayStationAdmin(admin.ModelAdmin):
    list_display = 'name', 'line'

# ...
```

Откроем страницу:

![SubwayStation change list page](/assets/images/posts/2013-04-12-django-admin-site-optimisation/station_list.png "SubwayStation change list page")

Видим, что на каждую станцию выводиться линия. Причем `__unicode__` у линии содержит еще и город Посмотрим на запросы к БД:

```sql
SELECT COUNT(*) FROM "main_subwaystation";
SELECT "main_subwaystation"."id", "main_subwaystation"."name", "main_subwaystation"."line_id", "main_subwayline"."id", "main_subwayline"."name", "main_subwayline"."city_id", "main_city"."id", "main_city"."name" FROM "main_subwaystation" INNER JOIN "main_subwayline" ON ("main_subwaystation"."line_id" = "main_subwayline"."id") INNER JOIN "main_city" ON ("main_subwayline"."city_id" = "main_city"."id") ORDER BY "main_subwaystation"."id" DESC;
```

Все выглядит здорово. Django [сам сделал select_related](https://docs.djangoproject.com/en/dev/ref/contrib/admin/#django.contrib.admin.ModelAdmin.list_select_related) на странице списка объектов. **Но здесь есть небольшая ловушка**. Читаем [документацию о select_related](https://docs.djangoproject.com/en/dev/ref/models/querysets/#django.db.models.query.QuerySet.select_related) внимательно, где написано

> Note that, by default, select_related() does not follow foreign keys that have null=True

Т.е. в нашем случае select_related() сработал, но только потому, что у поля `line` нет `null=True`.

Попробуем сделать теперь так:

`models.py`:

```python
# ...

class SubwayStation(models.Model):
    name = models.CharField(max_length=50)
    line = models.ForeignKey(SubwayLine, related_name='stations', null=True, blank=True)

    def __unicode__(self):
        return self.name

# ...
```

Открываем страницу списка станций и смотрим запросы:

```sql
SELECT COUNT(*) FROM "main_subwaystation";
SELECT "main_subwaystation"."id", "main_subwaystation"."name", "main_subwaystation"."line_id", "main_subwayline"."id", "main_subwayline"."name", "main_subwayline"."city_id" FROM "main_subwaystation" INNER JOIN "main_subwayline" ON ("main_subwaystation"."line_id" = "main_subwayline"."id") ORDER BY "main_subwaystation"  SC;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;
```

Опа. Так уже для отображения `__unicode__` каждой линии идет запрос города. Чтобы исправить ситуацию, нужно переопределить queryset для страницы списка объектов, указав явно в select_related нужные поля:

```python
# ...

class SubwayStationAdmin(admin.ModelAdmin):
    list_display = 'name', 'line'

    def queryset(self, request):
        qs = super(SubwayStationAdmin, self).queryset(request)
        qs = qs.select_related('line__city')
        return qs
# ...
```

Теперь с запросами все в порядке:

```sql
SELECT COUNT(*) FROM "main_subwaystation";
SELECT "main_subwaystation"."id", "main_subwaystation"."name", "main_subwaystation"."line_id", "main_subwayline"."id", "main_subwayline"."name", "main_subwayline"."city_id", "main_city"."id", "main_city"."name" FROM "main_subwaystation" INNER JOIN "main_subwayline" ON ("main_subwaystation"."line_id" = "main_subwayline"."id") LEFT OUTER JOIN "main_city" ON ("main_subwayline"."city_id" = "main_city"."id") ORDER BY "main_subwaystation"."id" DESC;
```
