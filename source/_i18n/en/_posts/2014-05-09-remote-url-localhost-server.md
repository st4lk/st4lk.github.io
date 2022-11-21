---
layout: post
title:  "Remote url for localhost server"
date:   2014-05-09 18:19:43 +0000
categories: deploy free
redirect_from:
  - /2014/remote-url-localhost-server/
---

[![Remote url for localhost server](/assets/images/posts/2014-05-09-remote-url-localhost-server/ngrok_logo.jpeg "Remote url for localhost server")]({{ site.baseurl }}{{ page.url }})

There is a nice tool called [ngrok](https://ngrok.com/). It allows to bind the URL for your localhost server!

<!--more-->

For example, you've launched a django development server on you computer:

```bash
python manage.py runserver
```

and this project can be accessed by remote URL.

### What for?

At least i can imagine such tasks:

- demonstrate project to customer
- check your site integration with payment system. For example paypal, where for receiving [IPN](https://developer.paypal.com/webapps/developer/docs/classic/products/instant-payment-notification/) messages you need a working site URL, even for sandbox

### How


- Download ngrok from [here](https://ngrok.com/download)
- Unpack downloaded archive
- Start django development server (by default on 8000 port)
- Start ngrok:
  ```bash
  ./ngrok 8000
  ```
- In console you'll see something like this:
  ```bash
  ngrok

  Tunnel Status                 online
  Version                       1.6/1.6
  Forwarding                    http://51c85c8a.ngrok.com -> 127.0.0.1:8000
  Forwarding                    https://51c85c8a.ngrok.com -> 127.0.0.1:8000
  Web Interface                 127.0.0.1:4040
  # Conn                        0
  Avg Conn Time                 0.00ms
  ```


Now your server is bind to http://51c85c8a.ngrok.com

### Improvements

It is not very useful, that on every start ngrok will generate new url like `********.ngrok.com`.

But we can assign custom subdomain and project can be accessed by the same url.

To do it we need:

- [register](https://ngrok.com/user/signup)
- take auth token
- let ngrok know your auth token (it is needed to do only once):

  ```bash
  ./ngrok -authtoken your_auth_token 8000
  ```
- set your custom subdomain like  this:

  ```bash
  ./ngrok  -subdomain=mysupersite 8000
  ```

After that our local server will be shown at http://mysupersite.ngrok.com.
