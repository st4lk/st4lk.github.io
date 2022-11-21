---
layout: post
title:  "Listen wifi with wireshark"
date:   2015-04-17 18:19:43 +0000
categories: fun security
redirect_from:
  - /2015/listen-wifi-with-wireshark/
---

[![Listen wifi with wireshark](https://img-fotki.yandex.ru/get/16098/85893628.c68/0_17f35c_4bf9a7fe_M.jpg "Listen wifi with wireshark")]({{ site.baseurl }}{{ page.url }})

I always knew, that it is possible to catch wifi network packets. But haven't done it in practise (i was analysing network packets, but not in HTTP protocol). So i decided to do it, as this is interesting and useful. Such experience help to understand TCP-IP and HTTP protocols and also to pay more attention for web security.

<!--more-->

We'll spy the network traffic with Wireshark program. There are a lot of tools for such purpose (ngrep, tcpdump, mitmproxy), but Wireshark looks the most popular and have a reach functionality.

Lets try to solve following tasks:

- [listen network packets, that are sent/recieved **inside local** machine](#localhost)
- [listen network packets, that are sent/recieved by **local** machine to/from outer world (internet)](#local_out)
- [listen network packets, that are sent/recieved by **other members of public wifi** network](#wifi_open_other)
- [listen network packets, that are sent/recieved by **other members of private wifi** network](#wifi_closed_other)

All actions i performed on laptop MacBook Pro with OS X Yosemite, so on other devices there can be some differences.

Disclaimer: all actions are on your own responsibility. Do not apply described technics to make bad things.

### Localhost network packets<a name="localhost"></a>

Install wireshark. Launch it, go to Capture -> Intefaces.

[![ws interface](https://img-fotki.yandex.ru/get/4509/85893628.c67/0_17f346_a2cf0b57_XL.png "ws interface")](https://img-fotki.yandex.ru/get/4509/85893628.c67/0_17f346_a2cf0b57_orig.png)

My laptop is connected to wifi only (en0 interface).
As i understand, awdl0 is a cable network. No cable is connected, so we don't see any packets.
And lo0 is a localhost interface, lets work with it now.

Put checkbox at lo0 and press Start.
To concentrate on HTTP protocol, set _Display filter: http_ (this filter will be applied to already fetched and decoded packets, unlike Capture filter, which i'll describe later):

[![ws http filter](https://img-fotki.yandex.ru/get/15599/85893628.c67/0_17f347_e85f8329_XL.png "ws http filter")](https://img-fotki.yandex.ru/get/15599/85893628.c67/0_17f347_e85f8329_orig.png)

We are gonna catch packets, that will be sent from browser to django development server and back. There are some things about django server, that worth mentioning.

- First, it respond HTTP 1.0, not HTTP 1.1
- Second, the most important, response can **not** include    
neither `Content-Length: <response length>`, neither `Transfer-Encoding: chunked`. In that case, to determine the end of HTTP response we need to wait for server to close the connection. But it will not happen. HTTP data can be transmitted in several TCP segments and wireshark smart enough to group those segments and to show final HTTP response. But, as wireshark can't understand exactly when response is completed, it will not group them in HTTP frame.

Well, this is not very bad, as we can always look for response to particular request by clicking on it and apply Analyse -> Follow TCP Stream. But, it will be great to see the HTTP response in frame list.

To do it, prepend `ConditionalGetMiddleware` to the list of `MIDDLEWARE_CLASSES`:

    if DEBUG:
        MIDDLEWARE_CLASSES = (
            'django.middleware.http.ConditionalGetMiddleware',
        ) + MIDDLEWARE_CLASSES

Middleware will set Content-Length header.

It is not necessary, but useful in case of working with wireshark and django dev server. In other cases all work correctly: production servers usually set `Transfer-Encoding: chunked` and respond HTTP by chunks (probably it is done by proxy server (nginx, apache, etc)).

Now start django project. The main page just shows the name of current user and login form. If current user is anonymous, then his name will be "AnonymousUser".

For the purity of the experiment clean cookies in browser for 127.0.0.1.
Open page [http://127.0.0.1:8000/](http://127.0.0.1:8000/).

If we have **not** add 'ConditionalGetMiddleware', then we'll probably see only request:

[![localhost request only](https://img-fotki.yandex.ru/get/4609/85893628.c68/0_17f349_2b69b414_XL.png "localhost request only")](https://img-fotki.yandex.ru/get/4609/85893628.c68/0_17f349_2b69b414_orig.png)

The response still can be found, if we choose _Analyse->Follow TCP Stream_:

[![localhost request only follow tcp](https://img-fotki.yandex.ru/get/6210/85893628.c68/0_17f34a_b9583d43_XL.png "localhost request only follow tcp")](https://img-fotki.yandex.ru/get/6210/85893628.c68/0_17f34a_b9583d43_orig.png)

And with 'ConditionalGetMiddleware' the response will be visible in list of frames:

[![localhost request response](https://img-fotki.yandex.ru/get/6307/85893628.c68/0_17f34b_617a4295_XL.png "localhost request response")](https://img-fotki.yandex.ru/get/6307/85893628.c68/0_17f34b_617a4295_orig.png)

Content-Length is set:

[![localhost request response follow tcp](https://img-fotki.yandex.ru/get/5820/85893628.c68/0_17f34c_f706aca8_XL.png "localhost request response follow tcp")](https://img-fotki.yandex.ru/get/5820/85893628.c68/0_17f34c_f706aca8_orig.png)

Well, it wasn't very interesting. But lets try to login!

Enter username and password and press Login. In wireshark we'll see 4 new frames: POST request, redirect to main page (302 code), GET / request, response for GET:

[![localhost four new frames](https://img-fotki.yandex.ru/get/16121/85893628.c68/0_17f34d_fc2e6c1b_XL.png "localhost four new frames")](https://img-fotki.yandex.ru/get/16121/85893628.c68/0_17f34d_fc2e6c1b_orig.png)

Look at fetched data more carefully.

Frame with POST request, along with HTTP headers contain form data. Here how they look like:

[![localhost login password](https://img-fotki.yandex.ru/get/5703/85893628.c68/0_17f34e_e290f091_XL.png "localhost login password")](https://img-fotki.yandex.ru/get/5703/85893628.c68/0_17f34e_e290f091_orig.png)

Login and password as plain text.

Response to POST request was 302 redirect. In that response server ask client to store session id in cookies:

[![localhost 302 session](https://img-fotki.yandex.ru/get/3110/85893628.c68/0_17f34f_664da61c_XL.png "localhost 302 session")](https://img-fotki.yandex.ru/get/3110/85893628.c68/0_17f34f_664da61c_orig.png)

Next goes GET request for main page, cookies now contain session id:

[![localhost session in request](https://img-fotki.yandex.ru/get/5302/85893628.c68/0_17f350_c48d0b1d_XL.png "localhost session in request")](https://img-fotki.yandex.ru/get/3110/85893628.c68/0_17f34f_664da61c_orig.png)

So this is how we can spy the network data, that is sent from client to server and back.
All these information will be transmitted in wifi network by the same way (if non secure HTTP protocol is used).
If we login - login and password are sent in plain text.
If we just make a requst - our session id is visible.

With session id it is easy to access the site as the owner of that session.
For simplicity, we can check that with console tool (curl, httpie).
Example with httpie:

```html
$ http 127.0.0.1:8000 "Cookie: sessionid=tmpocxkz6zsir6xe6i03kspucvlqq385"
HTTP/1.0 200 OK
Content-Length: 567
Content-Type: text/html; charset=utf-8
Date: Thu, 16 Apr 2015 13:06:58 GMT
Server: WSGIServer/0.1 Python/2.7.6
Set-Cookie:  csrftoken=3bUoLB28WyzcH7qG5GXreWPm0Pj11861; expires=Thu, 14-Apr-2016 13:06:58 GMT; Max-Age=31449600; Path=/
Vary: Cookie
X-Frame-Options: SAMEORIGIN

    <html>
        <body>
            Hello, alex
            <div>
                <form action="/login/" method="POST">
                    <input type="text" name="username" />
                    <input type="password" name="password" />
                    <input type="text" hidden name="next" value="/" />
                    <input type='hidden' name='csrfmiddlewaretoken' value='3bUoLB28WyzcH7qG5GXreWPm0Pj11861' />
                    <input type="submit" name="Login" value="Login" />
                </form>
            </div>
        </body>
    </html>
```

`Hello, alex` is shown, so the server treat us as alex.


### Network packets of local maching sent to outer world<a name="local_out"></a>

Listen for network packets of our computer.

In wireshark choose Capture -> Intefaces, apply en0 interface and press Start:

[![my wifi interface](https://img-fotki.yandex.ru/get/3000/85893628.c68/0_17f35a_55441968_XL.png "my wifi interface")](https://img-fotki.yandex.ru/get/3000/85893628.c68/0_17f35a_55441968_orig.png)

I access the admin page of this site (lexev.org). In wireshark set Display filter

```bash
http.request.full_uri contains lexev.org
```

to see data flow only with host lexev.org. Here what we get:

[![my wifi lexev](https://img-fotki.yandex.ru/get/6841/85893628.c68/0_17f35b_e70a8cfa_XL.png "my wifi lexev")](https://img-fotki.yandex.ru/get/6841/85893628.c68/0_17f35b_e70a8cfa_orig.png)

We have now a session id of admin user.


### Network packets of other members of public wifi network<a name="wifi_open_other"></a>

So far we were listening just our request and responses. But lets try to listen for other people.

Go to cafe with public wifi, launch wireshark.
Choose corresponding interface in Capture -> Intefaces and press Options (not Start).

We'll see something like this:

[![public wifi options](https://img-fotki.yandex.ru/get/6830/85893628.c68/0_17f355_9d02aa03_XL.png "public wifi options")](https://img-fotki.yandex.ru/get/6830/85893628.c68/0_17f355_9d02aa03_orig.png)

Double click on interface and put _Capture packets in monitor mode_ checkbox:

[![public wifi monitor model](https://img-fotki.yandex.ru/get/3107/85893628.c68/0_17f356_946d17dd_XL.png "public wifi monitor model")](https://img-fotki.yandex.ru/get/3107/85893628.c68/0_17f356_946d17dd_orig.png)

Ok, Start. Now we are listening entire wifi network (excluding yourself).

In public network fly a lot of packets, we can easily fetch more than Gb information in hour. Hard to work with such amount of data, that is where Capture filters can help. Packets that are discarded by capture filters will not be saved. Unlike display filters, they are applied to not yet processed and decrypted packets, therefore it is harder to construct the filter.

Here is a capture filter for HTTP GET and POST requests only on 80 port:

```bash
(port 80 and tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x47455420) or (tcp dst port 80 and (tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x504f5354))
```

Apply it at interface Options:

[![public wifi capture filter](https://img-fotki.yandex.ru/get/15496/85893628.c68/0_17f357_7d774c65_XL.png "public wifi capture filter")](https://img-fotki.yandex.ru/get/15496/85893628.c68/0_17f357_7d774c65_orig.png)

Lets try to connect to wifi from another device (phone for example) and send GET request to lexev.org from it.
For convenience add same display filter to show only requests to lexev.org (we can combine capture and display filters).
Session id is visible again:

[![public wifi admin session](https://img-fotki.yandex.ru/get/3613/85893628.c68/0_17f358_8b8382aa_XL.png "public wifi admin session")](https://img-fotki.yandex.ru/get/3613/85893628.c68/0_17f358_8b8382aa_orig.png)

Just for fun, lets try to login. Look for my password everyone :):

[![public wifi admin login and password](https://img-fotki.yandex.ru/get/15586/85893628.c68/0_17f359_d776258e_XL.png "public wifi admin login and password")](https://img-fotki.yandex.ru/get/15586/85893628.c68/0_17f359_d776258e_orig.png)

### Network packets of other members of private wifi network<a name="wifi_closed_other"></a>

For example we have a wifi with WPA protection.
Choose corresponding interface, enable monitor mode for it (the same way as for public network, just without capture filter) and listen.
We'll see something like this:

[![private undercrypted](https://img-fotki.yandex.ru/get/5113/85893628.c68/0_17f351_caf24487_XL.png "private undercrypted")](https://img-fotki.yandex.ru/get/5113/85893628.c68/0_17f351_caf24487_orig.png)

The data is encrypted. But, if we have a wifi password, we can decrypt it!

Go to Edit -> Preferences. Choose Protocol -> IEEE 802.11.

[![private IEEE](https://img-fotki.yandex.ru/get/5801/85893628.c68/0_17f352_eb1faebf_XL.png "private IEEE")](https://img-fotki.yandex.ru/get/5801/85893628.c68/0_17f352_eb1faebf_orig.png)

Press Edit for Decryption Keys. Press new. In popup enter:

```bash
Key type: wpa-pwd
Key: password:wifiname
```

[![private wifi password](https://img-fotki.yandex.ru/get/4913/85893628.c68/0_17f353_f8d36ba3_XL.png "private add password")](https://img-fotki.yandex.ru/get/4913/85893628.c68/0_17f353_f8d36ba3_orig.png)

Apply, ok.

Now wireshark will decrypt the packets and we can see HTTP data as before:

[![private wifi decrypted](https://img-fotki.yandex.ru/get/52/85893628.c68/0_17f354_19d29c5e_orig.png "private add decrypted")](https://img-fotki.yandex.ru/get/52/85893628.c68/0_17f354_19d29c5e_orig.png)

### Spy public wifi

I went to macdonalds with public wifi and for about an hour run wireshark (save only GET and POST HTTP requests).
Saved fetched data into pcap file (File -> Save as).
The question is, how to analyse such big amount of frames? Sometimes it is useful to export interesting data into CSV.
Use [tshark](https://www.wireshark.org/docs/man-pages/tshark.html) tool for that.

Save fields "frame number", "HTTP method", "full url" into results.csv:

```bash
tshark -r macdak_pushkin_get_post_only.pcap -T fields -e frame.number -e http.request.method -e http.request.full_uri > results.csv
```

Also i wrote small python script, that will count number of requests for each second-level domain.
The first 20 results:

| Domain | Number of requests |
| ------ | ------------------ |
| vk.com | 6280 |
| beeline.ru | 5407 |
| vk.me | 2817 |
| instagram.com | 867 |
| google.com | 544 |
| apple.com | 536 |
| yandex.ru | 473 |
| symcb.com | 471 |
| msftncsi.com | 441 |
| msn.com | 304 |
| yandex.net | 302 |
| trendmicro.com | 292 |
| co.uk | 270 |
| badoocdn.com | 258 |
| yadro.ru | 188 |
| marketgid.com | 184 |
| adfox.ru | 183 |
| mycdn.me | 165 |
| interfax.ru | 154 |
| scorecardresearch.com | 137 |


And yes, i've got couple of interesting sessions. For example, for site mamba.ru, session is transmitted by insecure HTTP protocol. So i copy the session, paste it in chrome using [EditThisCookie](https://chrome.google.com/webstore/detail/editthiscookie/fngmhnnpilhplaeedifhccceomclgfbg) plugin and voila, i am Sergey. I can read messages, look preferences and so on. Well, i just didn't want to harm Sergey, so i didn't make any POST requests.


### How to protect

The only way to protect your site is to use TLS (HTTPS). To apply it well many things must be checked, but such discussion worth to make another post. 

HTTPS traffic in wireshark:

[![private wifi decrypted](https://img-fotki.yandex.ru/get/15564/85893628.c68/0_17f348_d9eec045_orig.png "private add decrypted")](https://img-fotki.yandex.ru/get/15564/85893628.c68/0_17f348_d9eec045_orig.png)

All data is encrypted, we can't read it.

### Summary

- Use HTTPS were possible, especially if you deal with important user data (if it includes bank/card data, you must use https)
- Being in public wifi network and accessing site by http, keep in mind, that it is very easy to spy for you. It applies to private network also, attacker just need to know the wifi password.

### Useful links

- [Dan Callahan: Quick Wins for Better Website Security - PyCon 2014](https://www.youtube.com/watch?v=T-5p5ewqhVw)
- [Hynek Schlawack: The Sorry State of SSL - PyCon 2014](https://www.youtube.com/watch?v=SBQB_yS2K4M)
- [Benjamin Peterson - A Dive into TLS - PyCon 2015](http://www.youtube.com/watch?v=4o-xqqidvKA)
- [Ashwini Oruganti, Christopher Armstrong - Introduction to HTTPS: A Comedy of Errors - PyCon 2015](http://www.youtube.com/watch?v=HqnUKTjxI1E)
- [Getting comfortable with web security: A hands-on session - PyCon 2015](http://www.youtube.com/watch?v=f9XVNIeRxUo)
