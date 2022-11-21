---
layout: post
title:  "Send email in django project with mandrill service"
date:   2014-03-14 18:19:43 +0000
categories: api django email free
redirect_from:
  - /2014/send-email-django-project-mandrill-service/
---

[![Send email in django project with mandrill service](/assets/images/posts/2014-03-14-send-email-django-project-mandrill-service/mandrill-email.png "Send email in django project with mandrill service")]({{ site.baseurl }}{{ page.url }})

To send email messages from server we can just use SMTP protocol. But there is another way - special email services. I'll describe one of them here, [mandrill.com](http://mandrill.com/).

<!--more-->

### Advantages

- Detailed statistic of sent emails. How many were sent, to whom, when. How many were opened, what links were clicked.
- Message templates. They can be modified through mandrill service, no need to create anything in django admin. It is possible to use variables in templates, set subject, even address of sender. In django application you just specify the template name and the context (variables).
- No need of your own mail service. And no need to enable you domain in google/yandex mail (but still it will be useful).
- Free plan, that allows to send 12000 messages per month.

### Disadvantages

- For click statistic all links in you email will be replaced by special redirect urls. Probably regular users will not mention that.
- In some mail clients (for example gmail in browser) the field 'sender' along with specified address will contain the real address of mandrill. But it is possible to set DKIM and SPF DNS records for your domain, so sender address will be correctly shown everywhere.
- If you want to send more than 12000 messages per month, you need to buy corresponding plan.

To my mind, advantages are greater than disadvantages.

### Integration

1. Register on [https://mandrill.com/signup/](https://mandrill.com/signup/)

2. Create API_KEY:

[![Create API_KEY step 1](http://img-fotki.yandex.ru/get/9745/85893628.0/0_f6844_ecbf9fca_L.png
 "Create API_KEY step 1")](http://img-fotki.yandex.ru/get/9745/85893628.0/0_f6844_ecbf9fca_orig.png)

[![Create API_KEY step 2](http://img-fotki.yandex.ru/get/9805/85893628.0/0_f6845_733b2009_L.png
 "Create API_KEY step 2")](http://img-fotki.yandex.ru/get/9805/85893628.0/0_f6845_733b2009_orig.png)

[![Create API_KEY step 3](http://img-fotki.yandex.ru/get/9745/85893628.1/0_f6846_f8612a87_L.png
 "Create API_KEY step 3")](http://img-fotki.yandex.ru/get/9745/85893628.1/0_f6846_f8612a87_orig.png)<br/><br/><br/>
3. Create message template:

[![Create message template step 1](http://img-fotki.yandex.ru/get/9805/85893628.0/0_f6847_faf2f86c_L.png
 "Create message template step 1")](http://img-fotki.yandex.ru/get/9805/85893628.0/0_f6847_faf2f86c_orig.png)

[![Create message template step 2](http://img-fotki.yandex.ru/get/9745/85893628.1/0_f6848_d4286972_L.png
 "Create message template step 2")](http://img-fotki.yandex.ru/get/9745/85893628.1/0_f6848_d4286972_orig.png)<br/><br/>
3.1. Set template name (for example template-1):

[![Set template name](http://img-fotki.yandex.ru/get/9745/85893628.1/0_f6849_c232d9f3_L.png
 "Set template name")](http://img-fotki.yandex.ru/get/9745/85893628.1/0_f6849_c232d9f3_orig.png)<br/><br/><br/>
4. Edit the template contents:

[![Edit the template contents](http://img-fotki.yandex.ru/get/9745/85893628.1/0_f684a_b8b66799_L.png
 "Edit the template contents")](http://img-fotki.yandex.ru/get/9745/85893628.1/0_f684a_b8b66799_orig.png)


### Statistic example

1. Time send graph:

[![ГTime send graph](http://img-fotki.yandex.ru/get/9799/85893628.1/0_f684e_2538ff4a_L.png
 "Time send graph")](http://img-fotki.yandex.ru/get/9799/85893628.1/0_f684e_2538ff4a_orig.png)<br/><br/><br/>
2. Message open and link clicks graph:

[![Message open and link clicks graph](http://img-fotki.yandex.ru/get/9764/85893628.1/0_f684f_c33c7bb1_L.png
 "Message open and link clicks graph")](http://img-fotki.yandex.ru/get/9764/85893628.1/0_f684f_c33c7bb1_orig.png)<br/><br/><br/>
3. List of all sent messages:

[![List of all sent messages](http://img-fotki.yandex.ru/get/9828/85893628.1/0_f6850_89340ff9_L.png
 "List of all sent messages")](http://img-fotki.yandex.ru/get/9828/85893628.1/0_f6850_89340ff9_orig.png)<br/><br/><br/>
4. Link statistic:

[![Link statistic](http://img-fotki.yandex.ru/get/9764/85893628.1/0_f6851_de5ee46e_L.png
 "Link statistic")](http://img-fotki.yandex.ru/get/9764/85893628.1/0_f6851_de5ee46e_orig.png)<br/><br/><br/>

### Django integration

[Gist](https://gist.github.com/st4lk/9877661) contains example of integration with django and also standalone usage in python script.

<script src="https://gist.github.com/st4lk/9877661.js"></script>
