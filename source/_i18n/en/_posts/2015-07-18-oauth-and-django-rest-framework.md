---
layout: post
title:  "OAuth and django rest framework"
date:   2015-07-18 18:19:43 +0000
categories: api django oauth
redirect_from:
  - /2015/oauth-and-django-rest-framework/
  - /blog/2015/07/18/oauth-and-django-rest-framework.html
---

<a class="github-button" href="https://github.com/st4lk/django-rest-social-auth" data-color-scheme="no-preference: light; light: light; dark: dark;" data-size="large" data-show-count="true" aria-label="Star st4lk/django-rest-social-auth on GitHub">Star</a>

[![OAuth and django rest framework](https://img-fotki.yandex.ru/get/6615/85893628.c69/0_18e574_16d44873_XL.png
 "OAuth and django rest framework")]({{ site.baseurl }}{{ page.url }})

This is a well known topic, but i can't find the existing solution that will fully satisfy me. So i write it by myself :).

Assume we have a "single page" web site, that is talking with backend via REST API. Client side can be written with ember, angularjs or some like this. Backend - django rest framework (DRF). We've got a task - add social login  (OAuth protocol).

<!--more-->

How it will look like in case of simple "old-school" site? User press login, social network page is opening. Person confirms the access, resource redirects back to our web page, providing special code in redirected url. Using this code we do the login. For such process there are several existing libraries, my favourite is  [python-social-auth](https://github.com/omab/python-social-auth).

In case of single page site we can do the same. But, often development of frontend and backend are separated. Moreover, API can run on different subdomen, so backend can't handle redirected url.

So instead following scheme looks the most optimal. User press login, new popup window is opened with social network confirmation. User says yes, popup gets parameters from social resource, propagates them back to parent window (our frontend application). Finally, frontend sends these parameters to backend to finish login process.

Thus backend developer must implement API resource, that will take parameters from OAuth provider as input, and respond with user details as output, including session information (session id in cookies or token). Frontend will call this resource after receiving corresponding data from social network (OAuth provider).

The question is, what data it is better to send to that resource? Let's take OAuth 2.0. We have two choices: request token or access token. In first case server will need to exchange request token to access token by itself. In second case access token is already given (it was acquired by frontend). At first sight, the second approach is easier. But it has several disadvantages.

First, access token acquired by frontend have very short lifetime (couple of hours). We could save the access token in database for later usage (for example write something on user's wall). With short lifetime it will be not trivial. Second, access token will be sent by frontend to our server. It is a potential security issue. If our API is not running on HTTPS, then access token can be easily eavesdropped. This token is enough to make valid requests.

After searching for existing solutions, i've found [django-rest-auth](https://github.com/Tivix/django-rest-auth). 
It suggest resource, that takes access token as input. But there is no resource, that will take request token as input and do the rest of the work by itself. Also this package is built on top of [django-allauth](https://github.com/pennersr/django-allauth), which is not my favourite.

After summing all the things being said, i decided to write my own tool that will link django-rest-framework, python-social-auth and login resource with request token as input.

Here it is: [**django-rest-social-auth**](https://github.com/st4lk/django-rest-social-auth).

Details can be found in readme. This package is very small but useful (to my mind of course). All the customisation from python-social-auth is still available.

Live working example - site [woobie.ru](http://www.woobie.ru/), where this package is used.
