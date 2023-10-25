---
layout: post
title:  "Django: signal or model method?"
date:   2016-08-01 18:19:43 +0000
categories: django signal
redirect_from:
  - /2016/django-signal-or-model-method/
  - /blog/2016/08/01/django-signal-or-model-method.html
---

[![Django: signal or model method?](https://img-fotki.yandex.ru/get/95108/85893628.c69/0_1d577c_baad2650_orig.png
 "Django: signal or model method?")]({{ site.baseurl }}{{ page.url }})

When I needed to implement some functionality on model saving, I always asked a question to myself - where to place it. In signal or in model method `save()`? Let's see, what and when is more applicable.

<!--more-->

### When use model methods save(), delete()?

To my mind class methods are more usable, if logic concerns exclusively current model. For example, fill some field on model saving according to data from other fields.

Some people say, that signals are better because it is easy to reuse them. It seems strange to me because we can define a function or a mixin class and reuse it in method save() as well.

Generally, we can always use signals, so why I favor method save? Simple answer - it is more readable. When you are going through the model, you can easily understand, that something will happen on saving. In case of signals, especially if there is no rule where they are defined, the logic often come out of sight.

Keep in mind, that delete signals `pre_delete`, `post_delete` have some advantage over `delete()` method: they are [called](https://docs.djangoproject.com/en/1.9/topics/db/models/#overriding-predefined-model-methods) even on cascading delete and deleting a queryset. This is not happening with model method. In this situation make a decision according to context, maybe cascading delete is not so important.

On bulk creating and updating no code is executed: nor signal nor save(). So here they are equal.

And don't forget to call parent's method save() or delete() if you override them.

### When use signals?

Signals are more applicable when you implement reusable applications. The users of your app can easily connect signals to their models without modifying the code of these models. 

We can define a function or a mixin class for the same purpose. But agree, that attaching logic from some foreign app is more comfortable by using signals. Besides, if you decide to stop using the app, you will need to modify very small part of the project's code.

The same is true when there are two (or more) apps within one project and you need to do something with one model when another model from the different application is being saved.

Imagine two applications, users and reports. When we create a user we need to create automatically a report for that user. In this case, I prefer to create a signal in reports application, since logic corresponds to it.

Why?

Firstly, we keep logic in the place where it belongs. Secondly, if for some reason we decide to delete the reports app entirely, we don't even touch the users application.

### Where define signals and were connect them?

As [django docs](https://docs.djangoproject.com/en/1.9/topics/signals/#connecting-receiver-functions) (section "Where should this code live?") suggests, define signals in separate submodule `signals` and not in models.py and \_\_init\_\_.py. This will save you from import problems.

To be sure the signals are connected, we need to execute the code that connects them on project launch. When we define them in models.py, we already get this. But now they are living in other place and it won't run until we import it somewhere. Let's do it in `ready()` method of [application config class](https://docs.djangoproject.com/en/1.9/ref/applications/).

In general, I follow recommendations from [this](http://stackoverflow.com/a/22924754/821594) stackoverflow answer. Here is an example for users and reports applications, that I talked about earlier. We need to create a report on user creation.

1. Create submodule `signals` and place handlers.py in it

        reports/signals/__init__.py
        reports/signals/handlers.py

2. Define signals in that file handlers.py


        from django.db.models.signals import post_save
        from django.dispatch import receiver
        from django.contrib.auth import get_user_model

        from reports.models import Report

        User = get_user_model()

        @receiver(post_save, sender=User)
        def create_user_report(sender, instance, created, **kwargs):
            if created:
                Report.objects.create(user=instance)

3. Create application config class

        reports/apps.py

    with code:

        from django.apps import AppConfig

        class ReportsConfig(AppConfig):
            name = 'reports'
            verbose_name = 'Reports'

            def ready(self):
                import reports.signals.handlers  # noqa

    And now our signal is connected. In this example I used decorator `@receiver`, so just import is enough. We also could call `connect` method of the signal explicitly here. It is a matter of taste.

    Don't forget to define our `ReportsConfig` class as config of the application. To do it, place this code in reports/\_\_init\_\_.py:

        default_app_config = 'reports.apps.ReportsConfig'

    Or place ReportsConfig in your settings.INSTALLED_APPS. Look [django docs](https://docs.djangoproject.com/en/dev/ref/applications/#configuring-applications) for details.

If follow these rules we will always know where to find signal handlers. And consequently no need to search the models module to find them.

