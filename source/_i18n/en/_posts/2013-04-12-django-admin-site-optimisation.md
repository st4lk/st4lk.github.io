---
layout: post
title:  "Django admin site optimisation"
date:   2013-04-12 18:19:43 +0000
categories: django database sql
redirect_from:
  - /2013/django-admin-site-optimisation/
  - /blog/2013/04/12/django-admin-site-optimisation.html
---

[![Django admin site optimisation](/assets/images/posts/2013-04-12-django-admin-site-optimisation/django-admin-performance.png "Django admin site optimisation")]({{ site.baseurl }}{{ page.url }})

It is known, that less amount of database attempts leads to better performance. Usually admin page - part of site with low traffic, but anyway it is good, if no additional database calls happen there. It is more pleasant to use it, because page renders faster and also frees server resources.

In this post i'll try to reduce some database attempts in admin page, when model method `__unicode__` contains related object field. I suppose, that examples describe the situation more clear.

<!--more-->

### 1. __unicode__ at admin change form page

Lets take a look at following example: there are SubwayStation, SubwayLine and City models. SubwayLine is ForeignKey for SubwayStation and City - ForeignKey for SubwayLine.

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

Now visit SubwayStation change page

![SubwayStation change form page](/assets/images/posts/2013-04-12-django-admin-site-optimisation/station_change.png "SubwayStation change form page")

As we can see, `__unicode__` for SubwayLine consist of two fields: related City.name and its own SubwayLine.name.

Check database attempts were performed to show this page (attempts to tables django_session, auth_user, django_content_type are not taken into account) :

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

Following requests are made:

- first - get station record
- second - get all lines
- others - get city for each line

So we have (2 + amount of lines) attempts. It is a lot.

#### There are two ways to fix the situation

- Use [select_related](https://docs.djangoproject.com/en/dev/ref/models/querysets/#select-related) in queryset

    It is needed to define form for SubwayStation ModelAdmin:

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

    And now we have only two database calls (thanks to INNER JOIN):

    ```sql
    SELECT "main_subwaystation"."id", "main_subwaystation"."name", "main_subwaystation"."line_id" FROM "main_subwaystation" WHERE "main_subwaystation"."id" = 1 ;
    SELECT "main_subwayline"."id", "main_subwayline"."name", "main_subwayline"."city_id", "main_city"."id", "main_city"."name" FROM "main_subwayline" INNER JOIN "main_city" ON ("main_subwayline"."city_id" = "main_city"."id");
    ```

- Use [raw_id_fields](https://docs.djangoproject.com/en/dev/ref/contrib/admin/#django.contrib.admin.ModelAdmin.raw_id_fields) (usefull, when there are big amount of records so it is not comfortable and expensive to show them in selectbox)

    Set raw_id_fields for SubwayStationAdmin:

    `admin.py`:

    ```python
    class SubwayStationAdmin(admin.ModelAdmin):
        list_display = 'name',
        raw_id_fields = 'line',
    ```

    Here how page now looks like:

    ![SubwayStation change form page with line as raw_id_field](/assets/images/posts/2013-04-12-django-admin-site-optimisation/station_change_rawid.png "SubwayStation change form page with line as raw_id_field")

    Check database attempts:

    ```sql
    SELECT "main_subwaystation"."id", "main_subwaystation"."name", "main_subwaystation"."line_id" FROM "main_subwaystation" WHERE "main_subwaystation"."id" = 1 ;
    SELECT "main_subwayline"."id", "main_subwayline"."name", "main_subwayline"."city_id" FROM "main_subwayline" WHERE "main_subwayline"."id" = 1 ;
    SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;1,)
    ```

    Three calls, where third is for showing city in SubwayStations's __unicode__. Good. If we want, we can go further and make only two calls (exclude third request). We'll need to redefine ForeignKeyRawIdWidget widget:

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

    And now only two requests are made:

    ```sql
    SELECT "main_subwaystation"."id", "main_subwaystation"."name", "main_subwaystation"."line_id" FROM "main_subwaystation" WHERE "main_subwaystation"."id" = 1 ;
    SELECT "main_subwayline"."id", "main_subwayline"."name", "main_subwayline"."city_id", "main_city"."id", "main_city"."name" FROM "main_subwayline" INNER JOIN "main_city" ON ("main_subwayline"."city_id" = "main_city"."id") WHERE "main_subwayline"."id" = 1 ;
    ```

    Note, that given code with redefined ForeignKeyRawIdWidget will work with django 1.4, 1.5. For earlier version method `label_for_value` differs, so it is needed to copy this method from class ForeignKeyRawIdWidget from module django/contrib/admin/widgets.py and add to it `.select_related('city')`.

### 2. `__unicode__` in inline forms

Described solutions can be applied to inline admin objects. Lets say, that we have additional model District. And SubwayStation has ForeignKey to it:

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

As we can see, District `__unicode__` includes related field City.name. Now add SubwayStation as inline to SubwayLine:

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

Open SubwayLine change page:

![SubwayLine change form page with SubwayStation inline](/assets/images/posts/2013-04-12-django-admin-site-optimisation/line_change_inline.png "SubwayLine change form page with SubwayStation inline")

Check database calls (i've made only two stations for this line, and three districts in total):

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

For each inline station there is request to get all distrcits + for each district request to get city. Here we can exclude city request for each district by adding `select_related('city')` in Inline form:

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

Now there are no separate city requests:

```sql
SELECT "main_subwayline"."id", "main_subwayline"."name", "main_subwayline"."city_id" FROM "main_subwayline" WHERE "main_subwayline"."id" = 1 ;
SELECT "main_subwaystation"."id", "main_subwaystation"."name", "main_subwaystation"."line_id", "main_subwaystation"."district_id" FROM "main_subwaystation" WHERE "main_subwaystation"."line_id" = 1  ORDER BY "main_subwaystation"."id" ASC;
SELECT "main_city"."id", "main_city"."name" FROM "main_city" WHERE "main_city"."id" = 1 ;1,)
SELECT "main_city"."id", "main_city"."name" FROM "main_city";
SELECT "main_district"."id", "main_district"."name", "main_district"."city_id", "main_city"."id", "main_city"."name" FROM "main_district" INNER JOIN "main_city" ON ("main_district"."city_id" = "main_city"."id");
SELECT "main_district"."id", "main_district"."name", "main_district"."city_id", "main_city"."id", "main_city"."name" FROM "main_district" INNER JOIN "main_city" ON ("main_district"."city_id" = "main_city"."id");
SELECT "main_district"."id", "main_district"."name", "main_district"."city_id", "main_city"."id", "main_city"."name" FROM "main_district" INNER JOIN "main_city" ON ("main_district"."city_id" = "main_city"."id");
```

### 3. `__unicode__` at change list page

Lets look at SubwayStation change list page. I'll remind the code:

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

Open the page:

![SubwayStation change list page](/assets/images/posts/2013-04-12-django-admin-site-optimisation/station_list.png "SubwayStation change list page")

For each station there is line field. And __unicode__ of line includes city name.

Database attempts:

```sql
SELECT COUNT(*) FROM "main_subwaystation";
SELECT "main_subwaystation"."id", "main_subwaystation"."name", "main_subwaystation"."line_id", "main_subwayline"."id", "main_subwayline"."name", "main_subwayline"."city_id", "main_city"."id", "main_city"."name" FROM "main_subwaystation" INNER JOIN "main_subwayline" ON ("main_subwaystation"."line_id" = "main_subwayline"."id") INNER JOIN "main_city" ON ("main_subwayline"."city_id" = "main_city"."id") ORDER BY "main_subwaystation"."id" DESC;
```

Looks good. Django [have already used select_related](https://docs.djangoproject.com/en/dev/ref/contrib/admin/#django.contrib.admin.ModelAdmin.list_select_related) at change list page. **But there is a little trap**. Reading [documentation about select_related](https://docs.djangoproject.com/en/dev/ref/models/querysets/#django.db.models.query.QuerySet.select_related) carefully we can see, that

> by default, select_related() does not follow foreign keys that have null=True.

So in our case select_related works, because we don't have null=True for ForeignKey.

Lets add `null=True`:

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

Open change list page and look at database attempts:

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

Oops. Now, to show `__unicode__` for each SubwayLine separate database call to main_city table happens. To avoid this amount of calls, we have to redefine queryset for change list page (specify select_related with needed fields explicitly):

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

Now all good:

```sql
SELECT COUNT(*) FROM "main_subwaystation";
SELECT "main_subwaystation"."id", "main_subwaystation"."name", "main_subwaystation"."line_id", "main_subwayline"."id", "main_subwayline"."name", "main_subwayline"."city_id", "main_city"."id", "main_city"."name" FROM "main_subwaystation" INNER JOIN "main_subwayline" ON ("main_subwaystation"."line_id" = "main_subwayline"."id") LEFT OUTER JOIN "main_city" ON ("main_subwayline"."city_id" = "main_city"."id") ORDER BY "main_subwaystation"."id" DESC;
```
