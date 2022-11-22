---
layout: post
title:  "OAuth и django rest framework"
date:   2015-07-18 18:19:43 +0000
categories: api django oauth
redirect_from:
  - /2015/oauth-and-django-rest-framework/
---

<a class="github-button" href="https://github.com/st4lk/django-rest-social-auth" data-color-scheme="no-preference: light; light: light; dark: dark;" data-size="large" data-show-count="true" aria-label="Star st4lk/django-rest-social-auth on GitHub">Star</a>

[![OAuth и django rest framework](https://img-fotki.yandex.ru/get/6615/85893628.c69/0_18e574_16d44873_XL.png
 "OAuth и django rest framework")]({{ site.baseurl }}{{ page.url }})

Тема избитая, но мне не удалось найти готового решения, которое полностью бы меня устроило. Поэтому пишу сам :).

Итак, у нас есть "одностраничный" веб сайт, который общается с бекендом посредством REST API.  Клиентская часть может быть написана с помощью ember, angularjs или чего-то подобного. Бекенд - django rest framework (DRF). И есть тривиальная задача - добавить вход через социальные сети (OAuth протокол).

<!--more-->

Как бы это выглядело в случае обычного (олд-скульного) сайта? Пользователь нажимает логин, открывается страница социальной сети (Oauth провайдера). Человек подтверждает доступ, соц. сеть делает редирект обратно на наш сайт, передавая определенный код. Мы узнаем код из url'а и делаем логин. Для такого процесса есть несколько готовых django библиотек, мне больше всего нравится [python-social-auth](https://github.com/omab/python-social-auth).

В случае одностраничного сайта можно впринципе сделать так же. Однако, часто разработка фронтенда и бекенда разделена. Более того, бывает что апи работает на другом поддомене, таким образом бекенд не может напрямую обработать редирект.

В итоге следующая схема получается наиболее оптимальной. Пользователь нажимает логин, открывается попап окно с подтверждением в соц. сети. После подтверждения попап передает параметры родительскому окну (фронтенд приложению), который в свою очередь отправляет запрос на бекенд для конечного логина.

Т.о. бекенд разработчику нужно реализовать API ресурс, на вход которого передаются параметры от OAuth провайдера, а на выходе - данные пользователя + сессия (например id сессии в куках или токен). Этот ресурс будет вызываться фронтендом.

Вопрос, какие данные лучше передавать в этот ресурс? Возьмем OAuth 2.0. Тут два варианта - либо request token, либо access token. В первом случае сервер должен будет сам обменять request token на access token. Во втором - этого делать не надо (фронтенд уже получил access token). Казалось бы, последний вариант проще. Однако у этого способа есть недостатки.

Во-первых, access token, полученный фронтенд'ом, имеет очень маленький срок жизни (несколько часов). Мы могли бы сохранить access token в базе данных и при определенных условиях обратиться к социальной сети позднее (написать что-то на стене пользователя). С коротким сроком жизни токена это делать неудобно. Во-вторых, access token будет передан фронтендом на наш апи сервер. Возникает потенциальная угроза безопасности. Если наш апи работает не по HTTPS, то access token можно легко перехватить. Этого токена достаточно, чтобы делать валидные запросы.

Поискав готовые решения для DRF, я нашел [django-rest-auth](https://github.com/Tivix/django-rest-auth). Он предлагает готовый ресурс, который получает access token. А вот готового ресурса, который получал бы request token и все остальное делал бы сам, нету. Так же этот пакет основан на библиотеке [django-allauth](https://github.com/pennersr/django-allauth), которая по-моему мнению не очень удобна в части OAuth регистрации.

Исходя из всего вышесказанного, я решил написать свою тулзу, которая связывала бы django-rest-framework, python-social-auth и реализовывала ресурс для логина по request token'у.

Вот она: [**django-rest-social-auth**](https://github.com/st4lk/django-rest-social-auth).

Подробности по использованию можно почитать в readme. Это довольно маленький, но удобный пакет. Вся кастомизация, доступная в python-social-auth, доступна и здесь.

Живой пример - сайт [woobie.ru](http://www.woobie.ru/), там используется именно эта библиотека.
