---
layout: post
title:  "Слушаем wifi с помощью wireshark"
date:   2015-04-17 18:19:43 +0000
categories: fun security
redirect_from:
  - /2015/listen-wifi-with-wireshark/
  - /blog/2015/04/17/listen-wifi-with-wireshark.html
---

[![Слушаем wifi с помощью wireshark](https://img-fotki.yandex.ru/get/16098/85893628.c68/0_17f35c_4bf9a7fe_M.jpg "Слушаем wifi с помощью wireshark")]({{ site.baseurl }}{{ page.url }})

Всегда знал, что можно посмотреть сетевые пакеты, которые передаются по wifi сети. Но на практике этого не делал (на работе анализировал сетевые пакеты, но то был не HTTP протокол). Решил восполнить этот пробел, ведь это интересно и полезно. Более стройно выстраивается понимание протоколов TCP-IP и HTTP. Видно, как летят наши пароли и сессии, после такого опыта поневоле начинаешь относиться к безопасности сайта с большим трепетом.

<!--more-->

Трафик будем слушать с помощью программы Wireshark. Есть много утилит для анализа сетевой активности (ngrep, tcpdump, mitmproxy), но Wireshark пожалуй самая популярная и имеет огромный функционал.

Опишу работу программы на примере таких задач:

- [послушать сетевые пакеты, которые мы отправляем/принимаем **внутри локальной** машины (localhost)](#localhost)
- [послушать сетевые пакеты, которые отправляет/принимает наша **локальная** машина в/из внешнего мира (интернет)](#local_out)
- [послушать сетевые пакеты, которые отправляют/принимают **другие участники открытой wifi** сети](#wifi_open_other)
- [послушать сетевые пакеты, которые отправляют/принимают **другие участники закрытой wifi** сети](#wifi_closed_other)

Все действия я выполнял на ноутобуке MacBook Pro с OS X Yosemite, на других устройствах возможно что-то будет по-другому.

Небольшой дисклеймер: все ваши действия на вашей совести и ответсвенности. Не используйте описанные здесь техники во вред кому-либо.

### Сетевые пакеты локального интерфейса (localhost)<a name="localhost"></a>

Итак, устанавливаем wireshark. Запускаем, заходим в меню Capture -> Intefaces.

[![ws interface](https://img-fotki.yandex.ru/get/4509/85893628.c67/0_17f346_a2cf0b57_XL.png "ws interface")](https://img-fotki.yandex.ru/get/4509/85893628.c67/0_17f346_a2cf0b57_orig.png)

Я запускаю на ноутобуке, который подключен только к wifi сети (en0 интерфейс).
Насколько я понимаю, awdl0 - это кабельный сетевой интерфейс. По кабелю ноутбук никуда не подключен, поэтому и пакетов нет.
А lo0 - это локальный интерфейс, им сейчас и займемся.
Ставим галочку напротив него и нажимаем Start.
Чтобы сосредоточиться только на HTTP протоколе, зададим _Display filter: http_ (этот фильтр применяется к уже перехваченным и обработанным пакетам, в отличие от Capture filter, но о нем позднее):

[![ws http filter](https://img-fotki.yandex.ru/get/15599/85893628.c67/0_17f347_e85f8329_XL.png "ws http filter")](https://img-fotki.yandex.ru/get/15599/85893628.c67/0_17f347_e85f8329_orig.png)

Сейчас мы будем ловить сетевые пакеты, передающееся от нашего браузера к django development серверу и обратно.
Есть особенности, связанные именно с django сервером.

- Во-первых, он отдает HTTP 1.0, а не HTTP 1.1.
- Во-вторых, что более важно, в ответных HTTP заголовках может не быть    
ни `Content-Length: <response length>`, ни `Transfer-Encoding: chunked`. В этом случае для определения конца ответа нужно дождаться закрытия соединения с сервером, чего не происходит. Это имеет значение при работе с wireshark. Wireshark понимает большое количество протоколов, в том числе и HTTP. Данные HTTP протокола могут передаваться в нескольких TCP сегментах, но программа группирует эти сегменты и показывает нам итоговый HTTP запрос или ответ. С запросом проблем не возникает, но HTTP ответа не видно в списке фреймов wireshark, потому что она не понимает, что ответ уже закончен (нет ни Content-Length, ни Transfer-Encoding).

В принципе это не страшно, т.к. мы может нажать на фрейм запроса и выбрать из меню Analyse->Follow TCP Stream. В отдельном окне мы увидим HTTP запрос и соответствующий HTTP ответ (не важно, завершен он или нет). _Follow TCP Stream_ так же удобен в том случае, если HTTP запрос и ответ идут не по порядку (между ними могут случиться другие запросы). Т.е. мы выбираем запрос, нажимаем _Follow TCP Stream_ и видим всю цепочку сообщений.
Однако, мне хотелось видеть и запросы и ответы в списке фреймов.
Это мы можем сделать, добавив `ConditionalGetMiddleware` в список наших `MIDDLEWARE_CLASSES`:

```python
if DEBUG:
    MIDDLEWARE_CLASSES = (
        'django.middleware.http.ConditionalGetMiddleware',
    ) + MIDDLEWARE_CLASSES
```

Прослойка будет выставлять Content-Length в ответах.

Такое нужно только при работе с django development сервером и wireshark. В остальных случаях все работает: продакшн серверы выставляют `Transfer-Encoding: chunked` и отдают HTTP по кусочкам (вероятно это делает proxy сервер (nginx, apache)).

Теперь запустим простой django проект, который на главной странице отображает имя текущего пользователя, а так же форму для логина и пароля. Если пользователь не залогинен, то вместо имени показываем AnonymousUser.

Для чистоты эксперимента почистим все куки в браузере для адреса 127.0.0.1.
Откроем страницу [http://127.0.0.1:8000/](http://127.0.0.1:8000/).

Если мы **не** задали 'ConditionalGetMiddleware', то скорее всего увидим только запрос:

[![localhost request only](https://img-fotki.yandex.ru/get/4609/85893628.c68/0_17f349_2b69b414_XL.png "localhost request only")](https://img-fotki.yandex.ru/get/4609/85893628.c68/0_17f349_2b69b414_orig.png)

Ответ все же можно увидеть, выбрав запрос и зайдя в _Analyse->Follow TCP Stream_:

[![localhost request only follow tcp](https://img-fotki.yandex.ru/get/6210/85893628.c68/0_17f34a_b9583d43_XL.png "localhost request only follow tcp")](https://img-fotki.yandex.ru/get/6210/85893628.c68/0_17f34a_b9583d43_orig.png)

А если мы включили 'ConditionalGetMiddleware', то видим HTTP ответ уже в списке фреймов:

[![localhost request response](https://img-fotki.yandex.ru/get/6307/85893628.c68/0_17f34b_617a4295_XL.png "localhost request response")](https://img-fotki.yandex.ru/get/6307/85893628.c68/0_17f34b_617a4295_orig.png)

Content-Length задан:

[![localhost request response follow tcp](https://img-fotki.yandex.ru/get/5820/85893628.c68/0_17f34c_f706aca8_XL.png "localhost request response follow tcp")](https://img-fotki.yandex.ru/get/5820/85893628.c68/0_17f34c_f706aca8_orig.png)

Ну пока не очень интересно, только поковырялись с wireshark.
Но давайте попробуем залогиниться.

Вводим логин+пароль и нажимаем Login. В wireshark увидим 4 новых фрейма: POST запрос, редирект на главную страницу (ответ 302), запрос на получение главной, ответ главной страницы:

[![localhost four new frames](https://img-fotki.yandex.ru/get/16121/85893628.c68/0_17f34d_fc2e6c1b_XL.png "localhost four new frames")](https://img-fotki.yandex.ru/get/16121/85893628.c68/0_17f34d_fc2e6c1b_orig.png)

Проследим внимательно за передаваемой информацией.

Фрейм с POST запросом помимо HTTP заголовков содержит данные формы. Вот как они выглядят:

[![localhost login password](https://img-fotki.yandex.ru/get/5703/85893628.c68/0_17f34e_e290f091_XL.png "localhost login password")](https://img-fotki.yandex.ru/get/5703/85893628.c68/0_17f34e_e290f091_orig.png)

Логин и пароль как на ладони.

Ответом на POST запрос был фрейм с HTTP кодом 302 (редирект). В этом ответе сервер просит сохранить сессию в куках:

[![localhost 302 session](https://img-fotki.yandex.ru/get/3110/85893628.c68/0_17f34f_664da61c_XL.png "localhost 302 session")](https://img-fotki.yandex.ru/get/3110/85893628.c68/0_17f34f_664da61c_orig.png)

Следующим идет запрос главной страницы, в куках передается id сессии:

[![localhost session in request](https://img-fotki.yandex.ru/get/5302/85893628.c68/0_17f350_c48d0b1d_XL.png "localhost session in request")](https://img-fotki.yandex.ru/get/3110/85893628.c68/0_17f34f_664da61c_orig.png)

Вообщем вот так можно смотреть за данными, которыми обменивается ваше приложение с клиентом.
Все эти данные можно увидеть и в wifi сети, которые передаются любым пользователем (если идут запросы по незащищенному соединению http).
Если мы логинимся - виден логин/пароль.
Если просто отправляем запросы - виден id сессии.

Зная id сессии мы легко можем зайти под ее обладателем, просто записав их в наши куки.
Для простоты, можно проверить какой-нибудь консольной утилитой (curl, httpie).
Пример с httpie:

```bash
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

Вывелось `Hello, alex`, значит мы зашли под пользователем alex.


### Сетевые пакеты нашей локальной машины во внешний мир<a name="local_out"></a>

Послушаем внешние сетевые запросы нашего компьютера.

В wireshark выбираем Capture -> Intefaces, ставим галочку напротив en0 и нажимаем Start:

[![my wifi interface](https://img-fotki.yandex.ru/get/3000/85893628.c68/0_17f35a_55441968_XL.png "my wifi interface")](https://img-fotki.yandex.ru/get/3000/85893628.c68/0_17f35a_55441968_orig.png)

Зайду в админку этого сайта (lexev.org). В wireshark поставлю Display фильтр

```bash
http.request.full_uri contains lexev.org
```

чтобы видеть только запросы на домен lexev.org. Вот что получилось:

[![my wifi lexev](https://img-fotki.yandex.ru/get/6841/85893628.c68/0_17f35b_e70a8cfa_XL.png "my wifi lexev")](https://img-fotki.yandex.ru/get/6841/85893628.c68/0_17f35b_e70a8cfa_orig.png)

Видно id сессии, можно делать с ней все что захочешь.


### Сетевые пакеты других пользователей открытой wifi сети<a name="wifi_open_other"></a>

До сих пор мы слушали только свои запросы и ответы. Но гораздо интересней послушать других пользователей.

Зайдем в кафе с открытой wifi сетью, запустим wireshark.
Заходим в Capture -> Intefaces, выбираем соответствующий интерфейс и нажимаем Options (не Start).
Видим что-то такое:

[![public wifi options](https://img-fotki.yandex.ru/get/6830/85893628.c68/0_17f355_9d02aa03_XL.png "public wifi options")](https://img-fotki.yandex.ru/get/6830/85893628.c68/0_17f355_9d02aa03_orig.png)

Дважды щелкаем на интерфейс и ставим галочку напротив _Capture packets in monitor mode_:

[![public wifi monitor model](https://img-fotki.yandex.ru/get/3107/85893628.c68/0_17f356_946d17dd_XL.png "public wifi monitor model")](https://img-fotki.yandex.ru/get/3107/85893628.c68/0_17f356_946d17dd_orig.png)

Ok, Start. Все, теперь мы слушаем всю сеть (кроме нас самих).

В публичной wifi сети будет летать очень много пакетов, за час легко можно наловить больше Гб информации. Соответственно неудобно ее анализировать и сохранять. Тут пригодятся Capture фильтры, они применяются к еще не обработанным фреймам. Отсеченные фреймы этим фильтром не сохраняются. Отличие от Display фильтров в том, что мы работаем с нераскодированными данными, мы не знаем, что это - http или что-то другое. Поэтому Capture фильтры сложней составить.
Итак, давайте попробуем сохранять только HTTP запросы GET или POST на 80 порту.

Для этого зададим такой хитрый фильтр:

```bash
(port 80 and tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x47455420) or (tcp dst port 80 and (tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x504f5354))
```

на этапе выбора интерфейса (кнопка Options):

[![public wifi capture filter](https://img-fotki.yandex.ru/get/15496/85893628.c68/0_17f357_7d774c65_XL.png "public wifi capture filter")](https://img-fotki.yandex.ru/get/15496/85893628.c68/0_17f357_7d774c65_orig.png)

Попробуем подключиться с другого девайса (телефона) к этой wifi сети и опять отправим GET запрос на lexev.org.
Для удобства добавим тот же Display фильтр домена (Capture и Display фильтры можно комбинировать).
Видим id сессии:

[![public wifi admin session](https://img-fotki.yandex.ru/get/3613/85893628.c68/0_17f358_8b8382aa_XL.png "public wifi admin session")](https://img-fotki.yandex.ru/get/3613/85893628.c68/0_17f358_8b8382aa_orig.png)

Ради интереса попробуем войти, введя логин и пароль. Смотрите все:

[![public wifi admin login and password](https://img-fotki.yandex.ru/get/15586/85893628.c68/0_17f359_d776258e_XL.png "public wifi admin login and password")](https://img-fotki.yandex.ru/get/15586/85893628.c68/0_17f359_d776258e_orig.png)

Все как на ладони.

### Сетевые пакеты других пользователей в закрытой wifi сети<a name="wifi_closed_other"></a>

Допустим есть wifi сеть с WPA шифрованием.
В интерфейсах выберем wifi, включим для него monitor mode (все как для открытой сети, только без Capture фильтра) и попробуем послушать сетевые пакеты.
В результатах будет что-то такое:

[![private undercrypted](https://img-fotki.yandex.ru/get/5113/85893628.c68/0_17f351_caf24487_XL.png "private undercrypted")](https://img-fotki.yandex.ru/get/5113/85893628.c68/0_17f351_caf24487_orig.png)

Мы видим зашифрованные данные. Но, если мы знаем пароль от wifi, то можем расшифровать пакеты.
Для этого заходим в Edit -> Preferences. Выбираем Protocol -> IEEE 802.11.

[![private IEEE](https://img-fotki.yandex.ru/get/5801/85893628.c68/0_17f352_eb1faebf_XL.png "private IEEE")](https://img-fotki.yandex.ru/get/5801/85893628.c68/0_17f352_eb1faebf_orig.png)

Нажимаем Edit напротив Decryption Keys. Далее New. В новом окошке вводим:

```bash
Key type: wpa-pwd
Key: password:wifiname
```

Соответственно заменяем password на пароль от wifi сети, а wifiname - на название сети.

[![private wifi password](https://img-fotki.yandex.ru/get/4913/85893628.c68/0_17f353_f8d36ba3_XL.png "private add password")](https://img-fotki.yandex.ru/get/4913/85893628.c68/0_17f353_f8d36ba3_orig.png)

Apply, ok.

Все, теперь wireshark расшифровывает пакеты, и мы можем смотреть http данные как и раньше:

[![private wifi decrypted](https://img-fotki.yandex.ru/get/52/85893628.c68/0_17f354_19d29c5e_orig.png "private add decrypted")](https://img-fotki.yandex.ru/get/52/85893628.c68/0_17f354_19d29c5e_orig.png)

### Послушаем открытую wifi сеть

Ради интереса зашел в макдональдс и примерно на час запустил wireshark (ловил только GET и POST http запросы).
Далее сохранил все пакеты в файл pcap (File -> Save as).
Теперь вопрос, как проанализировать сохраненные фреймы? Их накопилось довольно много, вручную лазить по ним не удобно.
Воспользуемся программой [tshark](https://www.wireshark.org/docs/man-pages/tshark.html), с помощью нее можно выбрать нужные данные и записать их в CSV.

Вот так можно сохранить поля "номер фрейма", "HTTP метод", "full_uri"

```bash
tshark -r macdak_pushkin_get_post_only.pcap -T fields -e frame.number -e http.request.method -e http.request.full_uri > results.csv
```

Написав небольшой python скриптик, подсчитал количество запросов на каждый url и сгруппировал по доменам второго уровня.
Вот 20 самых популярных доменов, на которые заходили:

| Домен | Количество запросов |
| ----- | ------------------- |
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

Да, пару интересных сессий удалось перехватить. Например, для сайта знакомств mamba.ru, они передаются в открытую по HTTP.
Скопировал куки, вставил их в chrome с помощью плагина [EditThisCookie](https://chrome.google.com/webstore/detail/editthiscookie/fngmhnnpilhplaeedifhccceomclgfbg), зашел на сайт и вуаля, я - Сергей. Могу читать сообщения, смотреть настройки и прочее. Сразу скажу, что ничего я там не делал, посмотрел и вышел :).

### Способы защиты

Пожалуй единственным способом защиты является использование TLS (https). Здесь тоже есть нюанcы, его нужно использовать правильно. Описание правильной (и безопасной) работы с https заслуживает отдельного поста, так что тут не буду на этом останавливаться.

Вот как выглядит https трафик в wireshark:

[![private wifi decrypted](https://img-fotki.yandex.ru/get/15564/85893628.c68/0_17f348_d9eec045_orig.png "private add decrypted")](https://img-fotki.yandex.ru/get/15564/85893628.c68/0_17f348_d9eec045_orig.png)

Все данные зашифрованы, ничего не узнать.

### Итог

- По возможности используйте https, особенно если вы получаете какие-либо важные данные от пользователя (если что-то связано с банковскими данными/карточками, так вообще обязательно).
- Будучи в открытой wifi сети, заходя на сайт по незащищенному каналу (http) всегда помните, что вас можно легко прослушать. Это же относится и к закрытой wifi, злоумышленнику достаточно лишь узнать пароль от wifi.

### Полезные ссылки

- [Dan Callahan: Quick Wins for Better Website Security - PyCon 2014](https://www.youtube.com/watch?v=T-5p5ewqhVw)
- [Hynek Schlawack: The Sorry State of SSL - PyCon 2014](https://www.youtube.com/watch?v=SBQB_yS2K4M)
- [Benjamin Peterson - A Dive into TLS - PyCon 2015](http://www.youtube.com/watch?v=4o-xqqidvKA)
- [Ashwini Oruganti, Christopher Armstrong - Introduction to HTTPS: A Comedy of Errors - PyCon 2015](http://www.youtube.com/watch?v=HqnUKTjxI1E)
- [Getting comfortable with web security: A hands-on session - PyCon 2015](http://www.youtube.com/watch?v=f9XVNIeRxUo)
