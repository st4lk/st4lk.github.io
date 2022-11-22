---
layout: post
title:  "OAuth step by step"
date:   2015-05-16 18:19:43 +0000
categories: api oauth security
redirect_from:
  - /2015/oauth-step-step/
---

<div class="gist-wrp"><div class="github-btn" id="github-btn" style="float:right;"> <a class="gh-btn" id="gh-btn" href="https://gist.github.com/st4lk/4b71b72007a666435f81" target="_blank"> <span class="gh-ico"></span> <span class="gh-text" id="gh-text">Gist</span> </a></div></div>

[![OAuth step by step](https://img-fotki.yandex.ru/get/9819/85893628.c68/0_185253_82b5fefa_M.png "OAuth step by step")]({{ site.baseurl }}{{ page.url }})

OAuth protocol has two versions: 1.0 and 2.0.

Most of services today use version 2.0, i suppose because it is easier to implement.
Also, 2.0 can be realized in standalone applications (those, that don't have a server).

To understand the protocols very useful to have a look at their realisation.
Here i'll show several scripts that talk to OAuth providers of different versions.
Scripts will implement client application functionality.
Only standard python libraries are used. This help to overview the OAuth protocol - everything is on single screen and familiar. Of course, for production application we must use third party oauth libs, they handle many special cases and so on. Purpose of these scripts is just understanding of the protocol and nothing else.
It is often hard to keep the protocol flow in production-ready library, because it is splitted in many modules, some other packages are used. And the full vision is slipping out of sight.

<!--more-->

Let's refresh in mind some theory first.

For sure you know, that there are two objectives: _authentication_ and _authoriztion_.
They look very similar, but a little different in fact.
So, just to remember:

- authentication - process of identifying someone.

    We need to know, does this person really an owner of google account with exact id?
    This information is enough for us. Just login him and that's it, we don't need additional information or do something on behalf of the owner of account.

    Such work is done for example by OpenID protocol (although google suggest to to use [another means](https://developers.google.com/identity/sign-in/auth-migration#sign-in), OpenID - [deprecated](https://developers.google.com/identity/protocols/OpenID2)).

- authorization - process of acquiring rights to do something.

    Authorization already includes authentication, but gives more power.
    For example, not just identify some person, but also get his email and maybe post a message on his wall.

    That is what OAuth protocol for.

To remember i use word "author". If objective contains "author" - we are talking about permissions (authority). Otherwise just an identification.

### OAuth 1.0

Specification: [http://tools.ietf.org/html/rfc5849](http://tools.ietf.org/html/rfc5849)

The main part to remember about OAuth 1.0 - it signs **all** requests with secret key.
Secret key must be kept in safe place, the only one is server.
Protocol provides fully security, even if https is not used.
By saying "security" i mean the following: once the request was eavesdropped, the hacker can't create new valid request.
Of course he can get the data being transmitted, to hide the data we still need the https.

<script src="https://gist.github.com/st4lk/314e181faaea7d671d0e.js"></script>

### OAuth 1.0 less-legged (2-legged, 1-legged, 0-legged)

It is a modification of OAuth 1.0, were user is not interacted in process.
Formally speaking, it is not an OAuth anymore, as specification doesn't describe such modification.
Just same means are used.
In this case client application is acting as a user. It can request either public resources, either his own resources (even private).

<script src="https://gist.github.com/st4lk/719729c03cf0314179b4.js"></script>

### OAuth 2.0 with server

Specification: [http://tools.ietf.org/html/rfc6749](http://tools.ietf.org/html/rfc6749)

Interesting, that in title of OAuth 2.0 specification it is called "framework".
Whereas in title of OAuth 1.0 [specification](http://tools.ietf.org/html/rfc5849) it is called protocol.

To get full security with OAuth 2.0, https is mandatory (service provider **must** use https, for example facebook).
Once the access_token is acquired, secret key is not needed.
So if someone will steal the access_token, he can make a valid request. That is why https is needed, to hide access_token.
Also, during acquiring the access_token, secret key is transmitted by HTTP as is.

access_token always have limited time to live.

Because of all said above (and something else), one of creators of OAuth 1.0 protocol has left the OAuth 2.0 team, as 2.0 is very easy to implement insecurely.
For details follow this [link](http://hueniverse.com/2012/07/26/oauth-2-0-and-the-road-to-hell/).

Here is a sequence of steps to get OAuth 2.0 access_token, if you have a server.
Server use secret key to get an access_token. Pay attention, no crypto library is used.

<script src="https://gist.github.com/st4lk/4b71b72007a666435f81.js"></script>

### OAuth 2.0 without server

OAuth 2.0 client can be implemented without server. In that case we also get an access_token, but we don't need to know the secret key at all! Usually such access_token have a small time to live (1-2 hours), whereas time to live of access_token, acquired by server, is longer (can be several tens of days).

<script src="https://gist.github.com/st4lk/af1db97e36897b918f22.js"></script>
