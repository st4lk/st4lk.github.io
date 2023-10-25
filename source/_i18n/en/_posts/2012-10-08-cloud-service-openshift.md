---
layout: post
title:  "Cloud service Openshift"
date:   2012-10-08 18:19:43 +0000
categories: free openshift python
redirect_from:
  - /2012/cloud-service-openshift/
  - /blog/2012/10/08/cloud-service-openshift.html
---

[![Cloud service Openshift](/assets/images/posts/2012-10-08-cloud-service-openshift/openshift-icon.png "Cloud service Openshift")]({{ site.baseurl }}{{ page.url }})

I know a few hosting providers with free account and python availability. It is [Google App Engine](https://appengine.google.com/) and [Alwaysdata](https://www.alwaysdata.com/). But recently i found great project [Openshift](https://openshift.redhat.com/) from RedHat and this blog site is working on it. Let me describe mentioned hostings first.

<!--more-->

### Google app engine

The main trouble of google app engine - limited amount of python libraries. Of course, you can use pure python libs, but you can't setup libs that requires C compilation. For example, pycurl library can't be used. Also GAE uses special data bases, so libs to work with them are also special. Therefore starting of django application is not trivial, because django works with SQL databases. In additional, django can be used only with version 1.2, 1.3 (while 1.4 currently avaliable). Anyway, here some useful links: [list of avaliable libraries](https://developers.google.com/appengine/docs/python/tools/libraries27), [django-rocket-engine project](http://django-rocket-engine.readthedocs.org/).

### Alwaysdata

With free account you can't setup libraries, that requires C compilation. But here we have familiar data bases - mysql, postgres, mongodb. So usual django application can be started easily. I often use this hosting to demonstrate simple projects.

## Openshift

Openshift - it is PaaS, i.e. platform as a service. We don't have root access to operating system. The system is provided to us by service in a working state, and we can make only limited amount of actions on it. It is similiar to google app engine, but here we have much more freedom.

First of all it is great, that many things can be installed manually. Any version of python, django. If you want SQL/Postgres/mongodb as data base - you are welcome. You can setup libraries and compile them. There are additional cool things: cron, statistics, phpmyadmin and etc. I've mentioned django, but it is possible to use any framework, it just what i've tried.

Handy style of deploying appliction on server. Just type git push special_application_url from you git-repository and thats it! Files automaticly refreshes on server and server restarts. Process of restarting can be managed by special scripts. For example, you can tell the script to setup necessary libraries from requirements.txt, compile static files (manage.py collectstatic) and so on. This script will be runned at every server restart.

For free account it is available 1 Gb of disc space and 3 small 'gears'. As I understand, gear - it is some isolated environment with its RAM. For a small gear size of RAM is equal to 512. If power of one gear is not enough, then second is started, then third and so on. To keep it simple, here is example of load, that simple DLE site can process (from [openshift](https://openshift.redhat.com/community/developers/pricing) description):


_15 pages/second, Hundreds of articles, 50k visitors per month_.

For a simple site it is quite enough. For one account you can create 3 applications (at least for free). Of course, there is possibility, that this freebie will end at some time. But existing code you can always run at other hosting - it doesn't have special featers as GAE does. Finally you can buy payment account at openshift.

On openshift site it is described in detail, how to start application. I will describe my experience.

#### Steps to start python 2.7.3 + django application

- register
- setup git (if not already)
- setup special program "rhc" (it can be skipped, but this program helps a lot), manul: [get-started](https://openshift.redhat.com/community/get-started)
- follow instructions [https://github.com/ehazlett/openshift-diy-py27-django](https://github.com/ehazlett/openshift-diy-py27-django) (simple application without data base)
- or follow instructions [https://github.com/st4lk/lexev](https://github.com/st4lk/lexev) (application with mysql, the code of this blog)

That it! Application is available at `http://<app_name>-<namespace>.rhcloud.com/`


### Link to domain

Well, not quite yet. It will be nice to have normal address... Suppose we have domain (for example lexev.org). Lets link our application to that domain.

Openshift doesn't have DNS servers, that can be set for domain. Instead of it Openshift sujest to use [CNAME](http://en.wikipedia.org/wiki/CNAME_record). It can be done in domain management page.

That all nice, but i've bought my domain at nic.ru. To create CNAME record there i must buy additional access... But, as it turned out, there is way out! Let's use free service [http://freedns.afraid.org](http://freedns.afraid.org/).

So,

- register at freedns.afraid.org
- set DNS servers for domain:

	```
	ns1.afraid.org
	ns2.afraid.org
	ns3.afraid.org
	ns4.afraid.org
	```

- add domain at afraid.org: [http://freedns.afraid.org/domain/add.php](http://freedns.afraid.org/domain/add.php), in my case it is lexev.org. Don't forget to select Shared State: Private, or you domain will be avaliable to all users at afraid.org

- for newly created domain add subdomen with type CNAME, as on picture (replace lexev.org to needed domain and set correct url of application at destination field):

	![afraid.org CNAME](/assets/images/posts/2012-10-08-cloud-service-openshift/afraid.com-1.png "afraid.org CNAME")

- at subdomens page we see two records: one with CNAME and one without (it is on top probably)
- press record without CNAME
- change nothing, but click "Forward to a URL"
- type as on picture (again replace lexev.org to needed domain):

	![afraid.org Forward to a URL](/assets/images/posts/2012-10-08-cloud-service-openshift/afraid.com-2.png "afraid.org Forward to a URL")

- finally the subdomens must be:

	![afraid.org subdomain](/assets/images/posts/2012-10-08-cloud-service-openshift/afraid.com-3.png "afraid.org subdomain")

For now looks that all done. Some time will be needed for new DNS servers to start work with newly domain.

Request to lexev.org will be redirected to [www.lexev.org](http://www.lexev.org/). And [www.lexev.org](http://www.lexev.org/) points to application at openshift.

It should be noted, that openshift also supports PHP, Ruby, Java, Node.js, Perl !

Thanks for reading and sorry for my english! :)
