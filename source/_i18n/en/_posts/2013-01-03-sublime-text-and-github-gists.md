---
layout: post
title:  "Sublime text and github gists"
date:   2013-01-03 18:19:43 +0000
categories: sublime
redirect_from:
  - /2013/sublime-text-and-github-gists/
  - /blog/2013/01/03/sublime-text-and-github-gists.html
---

[![Sublime and github gist](/assets/images/posts/2013-01-03-sublime-text-and-github-gists/logo_full.jpeg "Sublime and github gist")]({{ site.baseurl }}{{ page.url }})

In [Sublime text](http://www.sublimetext.com/) there are big variety of useful tools, that help to write code. I've learned only a small part of them, currently i'm trying to write in Vintage mode (vim style cursor management). But now i want to tell about integration [github gists](https://gist.github.com/) with sublime text. If you don't now, github gists let you save snippets as a separate file without creation full repository. But it have many repository features - versions, possibility to fork.

<!--more-->

### What we'll have at the end

Save snippet from sublime, give to it description with key words. Then again from sublime we can find snippet by key words and see it in editor. All snippets are saved in github, so they are avaliable from other computers.

Remember, that sublime text has its own snippet functionality. But it is more preferable for small auto insertion. For example, when you write `def` in python, insert function template:

```python
def function():
    pass
```

Github gist are more suitable for something bigger - some function for exact purpose.

### Lets setup this functionality

#### Gist plugin setup

The easiest way to do it is with sublime package manager. [Here](http://wbond.net/sublime_packages/package_control/installation) is instruction for setup. In sublime press `ctrl + shift + p`, enter `install` and then `gist`:

![Sublime install package](/assets/images/posts/2013-01-03-sublime-text-and-github-gists/1_package_control_install.jpeg "Sublime install package")

![Sublime install gist package](/assets/images/posts/2013-01-03-sublime-text-and-github-gists/2_package_control_gist.jpeg "Sublime install gist package")

#### Give access to your github account

Press Preferences->Package settigns->Gist->Settings User.

![Gist sublime Preferences](/assets/images/posts/2013-01-03-sublime-text-and-github-gists/3_gist_settings_menu.jpeg "Gist sublime Preferences")

You can either set login + password, either token. If needed settings are not in Settings User, then they can be copied from Settings Default. But don't change default settings. To receive token, run in system command line ([curl](http://curl.haxx.se/) must be installed):

```bash
curl -v -u USERNAME -X POST https://api.github.com/authorizations --data "{\"scopes\":[\"gist\"]}"
```

where USERNAME - your github login

![Gist sublime settings](/assets/images/posts/2013-01-03-sublime-text-and-github-gists/4_gist_auth.jpeg "Gist sublime settings")

#### Gist creation

Write code of your snippet in new sublime tab. I wrote code for taking content of csv file as list of lists. Press `ctrl + shift + p`, then `gist create public` and enter. Here is avaliable fuzzy searching, so i just enter `public`.

![Gist sublime create](/assets/images/posts/2013-01-03-sublime-text-and-github-gists/5_gist_create_public.jpeg "Gist sublime create")

Give description to our snippet. It is important to include meaningful words, because search will use them. I write "Python: Get csv lines".

![Gist sublime description](/assets/images/posts/2013-01-03-sublime-text-and-github-gists/6_gist_set_description.jpeg "Gist sublime description")

There will be also request for file name, it can be skipped by pressing enter.

#### Search for a gist

Open sublime command line by pressing `ctrl + shift + p` and enter `gist open`.

![Gist sublime open](/assets/images/posts/2013-01-03-sublime-text-and-github-gists/7_gist_open.jpeg "Gist sublime open")

Then enter key words "python csv"

![Gist sublime find](/assets/images/posts/2013-01-03-sublime-text-and-github-gists/8_gist_find_by_descr.jpeg "Gist sublime find")

And see our snippet.

![Gist sublime opened](/assets/images/posts/2013-01-03-sublime-text-and-github-gists/9_gist_opened.jpeg "Gist sublime opened")


This snippet is also created at github: [https://gist.github.com/3931305](https://gist.github.com/3931305).

#### Links

- Code editor [sublime text](http://www.sublimetext.com/)
- [Repo](https://github.com/condemil/Gist) of Gist plugin
- [Video lesson](https://tutsplus.com/lesson/sexy-code-snippet-management-with-gists/) about sublime and gist at [tutsplus.com](http://tutsplus.com/)
- [Video course](https://tutsplus.com/course/improve-workflow-in-sublime-text-2/) about sublime at [tutsplus.com](http://tutsplus.com/)
