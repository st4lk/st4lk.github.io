---
layout: post
title:  "Sublime Text and Language Server Protocol"
date:   2019-02-19 18:19:43 +0000
categories: python sublime lsp
redirect_from:
  - /2019/sublime-text-and-language-server-protocol-lsp/
image: https://i.ibb.co/4K4zp06/sublime-256-lsp-light.png
---

[![Sublime Text and Language Server Protocol (LSP)](https://i.ibb.co/4K4zp06/sublime-256-lsp-light.png
 "Sublime Text and Language Server Protocol (LSP)")]({{ site.baseurl }}{{ page.url }})

Language Server Protocol (LSP)
---
LSP - protocol for interactions between IDE and language server. The latter provides such means like autocompletion, goto implementation and etc. When IDE needs to show autocomplete choices on, for example, python language - it sends a request to the special server. And it responds with the necessary data. The cool part here is that it is an initiative of a big company - Microsoft.

<!--more-->

But what is the point, in almost all popular IDEs such features are already available out of the box?

I think the main point is unification of implementation. We can have a single server with many IDEs. No need to develop standard means in each IDE separately. The only thing that must be done - is to implement protocol for communication with the language server.

There is also an advantage from the perspective of IDE user. When some feature will be added to the language server, you'll receive it for free and immediately. It doesn't matter what exact IDE you are using, it is independent now. The main part that must be supported by your code editor - is language server protocol. We can assume that it will be stable in near future since it is supported by such giant as Microsoft.

Some useful links:

- Official website of LSP: [https://microsoft.github.io/language-server-protocol/](https://microsoft.github.io/language-server-protocol/)
- The list of server implementations: [https://microsoft.github.io/language-server-protocol/implementors/servers/](https://microsoft.github.io/language-server-protocol/implementors/servers/)
- Community-driven website: [https://langserver.org/](https://langserver.org/)

Python Server
------------
Let's try to connect IDE (Sublime Text will be used in this article) with python language server.

The first thing that we'll need - is the server itself, it will respond to LSP requests. At the time this post was written, the most active project implemented in python was: [https://github.com/palantir/python-language-server](https://github.com/palantir/python-language-server).

There is a server from Microsoft as well: [https://github.com/Microsoft/python-language-server/](https://github.com/Microsoft/python-language-server/).
And it even has [the short instruction](https://github.com/Microsoft/python-language-server/blob/master/Using_in_sublime_text.md) how to setup Sublime Text for it. This server requires [dotnet](https://dotnet.microsoft.com/download/dotnet-core/2.1) to be installed in your system.
I tried to launch it, but it didn't provide all the features that I needed. Maybe I didn't set it up correctly. And I rarely (well, never :)) use C# in my work, so it is hard to understand the details of implementation. This is not required to be able to use, but sometimes I like to do small tweaks and it will be hard to do in C# for me.

So let's return to the server written in python. I had such a plan in my mind:

1. We have a separate virtualenv, that was created exclusively for LSP server
2. We keep clean the virtualenv of our working project, i.e. there is no LSP server installed in it
3. During communication with the server, our IDE will tell which virtualenv to use (to indicate environment of current project)

In total, we can install LSP server only once and use it for different projects.
It wasn't obvious how to do it at the time this post was written. At least I didn't find a definite guide on how to do it. In the documentation for the python server it was implicitly assumed that server will be installed in the same virtualenv as the project. To my mind this is not useful, so I created a [PR](https://github.com/palantir/python-language-server/pull/401).

Also, this LSP didn't use my linter settings. For example, in the root folder of the project I have `setup.cfg` file with such params:

    ignore = D202,D205,D211
    max-line-length = 99

To make LSP use it I have to create another [PR](https://github.com/palantir/python-language-server/pull/413), which in turn migrated to [this one](https://github.com/palantir/python-language-server/pull/418).

There were other problems and sometimes they required PRs as well. I hope, that all of them will be included in release soon. Meanwhile, there is release in my [fork](https://github.com/st4lk/python-language-server/releases/tag/0.22.0a1), it contains mentioned fixes.

To be precise:

- Create a separate virtualenv for LSP server. Better to use python3.6+.
- Install server there (the release that I mentioned above ^):

        pip install https://github.com/st4lk/python-language-server/archive/0.22.0a1.zip

If you want to use requirements.txt - then just add a link to zip file there as is, no need to use any prefix/suffix.

It is possible, that at the moment when you read this post, all the fixes are already included in official version `> 0.22` (or they were fixed by other commits). It worth checking the changelog of the current version.

Sublime Text
------------

Let's move to IDE setup. I'll describe Sublime Text in this article. I like this code editor, although it is not an IDE strictly speaking. I like its speed, vintage mode, multi-cursors and many other features.

So, how to connect Sublime Text with LSP server?
First of all we'll need to install a plugin for LSP: [https://github.com/tomv564/LSP](https://github.com/tomv564/LSP).

The most important thing - to setup it properly.
Go to plugin settings (on MacOS it is _Sublime Text -> Preferences -> Package Settings -> LSP -> Settings_).
In user's settings type something like:

    {
      "clients": {
        "pyls":
        {
          "enabled": true,
          "command": [
            "~/.virtualenvs/python-language-server/bin/pyls"
          ],
          "settings": {
            "pyls": {
              "configurationSources": ["flake8"],
              "plugins": {
                "jedi_definition": {
                  "follow_imports": true
                }
              }
            }
          },
          "scopes": ["source.python"],
          "syntaxes": [
            "Packages/Python/Python.sublime-syntax",
            "Packages/Djaneiro/Syntaxes/Python Django.tmLanguage"
          ],
          "languageId": "python"
        }
      }
    }

Let's speak about the most important parameters.

**"command"** - path to executable file of pyls server. As you can see, on my computer it is installed in virtualenv  `~/.virtualenvs/python-language-server/` (I use [virtualenvwrapper](https://virtualenvwrapper.readthedocs.io/en/latest/)). This is not a virtualenv of your project! Here we have only pyls and nothing else.

**"settings" : "pyls" : "configurationSources"**. Here we can specify the source of linter settings. By default it is "pycodestyle", but I usually use flake8. So pyls will search following files:

    '.flake8', 'setup.cfg' (section [flake8]), 'tox.ini'

**"follow_imports": true**. An important setting, without it goto will show only the _import_ place, but not the source code. To my mind, such behavior is not very useful, it is more interesting to look at actual implementation, instead of just import path. To make it work I have to tweak the server a little bit: [https://github.com/palantir/python-language-server/pull/404/](https://github.com/palantir/python-language-server/pull/404/).

Another valuable thing: **"syntaxes"** setting. If you are using plugin like [Djaneiro](https://github.com/squ1b3r/Djaneiro) (it adds some cool autocompletion, snippets for Django project), then Sublime Text will treat syntax of python files as Djaneiro, not as the default Python. So need to specify it for our LSP server. Otherwise, editor will not launch it.

We have defined global settings that will be used for all python fileds. But how to define settings specific for concrete project?

Surprisingly, you can specify them in project settings :). Go to _Project -> Edit project_ and add the following:


    {
      "folders":
      [
          {
              "path": "/Path/to/my/project"
          },
      ],
      "settings":
      {
        "LSP":
        {
          "pyls":
          {
            "env":
            {
              "VIRTUAL_ENV": "/path/to/my/project/virtualenv/"
            }
          }
        }
      }
    }

By using **"VIRTUAL_ENV"** we can point to project's virtualenv, so pyls will know where to search installed packages for autocompletion, goto end etc.

Ok, let's launch all of it. Imagine that we have such django project:

    project
    ├── ...
    ├── my_app
    │   ├── ...
    │   ├── forms.py
    │   └── models.py
    ├── manage.py
    └── setup.cfg

The simplest models.py file:


    from django.db import models


    class Book(models.Model):
        """
        This is docstring of Book model.
        Example for LSP demostration.
        """

        title = models.CharField(max_length=50)

and forms.py:


    from django.forms import ModelForm
    from .models import Book


    class BookForm(ModelForm):

        class Meta:
            model = Book
            fields = '__all__'

In setup.cfg we have `[flake8]` section:

    [flake8]
    ignore = D202,D205,D211
    max-line-length = 99

What do we get now?
Server will provide features of [jedi](https://jedi.readthedocs.io/en/latest/) out of the box, for example, Definitions (goto), References, autocomplete.

On hover you'll see the doscstring of the object, as well as available actions:

![Sublime Text and Language Server Protocol (LSP): cursor hover window with documentation and actions](https://i.ibb.co/0yW1sRd/sublime-lsp-popup-with-docstring-and-actions.png
 "Sublime Text and Language Server Protocol (LSP): cursor hover window with documentation and actions")

If you'll click on Definition you will jump to class implementation.
On click on References - all usages will be shown:

![Sublime Text and Language Server Protocol (LSP): References](https://i.ibb.co/26LW2ys/sublime-lsp-references.png
 "Sublime Text a d Language Server Protocol (LSP): References")

Autocomplete is also working:

![Sublime Text and Language Server Protocol (LSP): methods autocomplete](https://i.ibb.co/cb2gKDJ/sublime-lsp-autocomplete-methods.png
 "Sublime Text and Language Server Protocol (LSP): methods autocomplete")

![Sublime Text and Language Server Protocol (LSP): fields autcomplete](https://i.ibb.co/zQ6ZXHh/sublime-lsp-autocomplete-fields.png
 "Sublime Text and Language Server Protocol (LSP): fields autcomplete")

But syntax errors and pep8 rules violation will not be shown. To make it work, need to install following packages into virtualenv where your LSP server is running:

    pip install mccabe
    pip install pyflakes
    pip install pycodestyle

Voila, now editor will show warnings:

![Sublime Text and Language Server Protocol (LSP): syntax error](https://i.ibb.co/VYCWVtY/sublime-lsp-invalid-syntax.png
 "Sublime Text and Language Server Protocol (LSP): syntax error")

![Sublime Text and Language Server Protocol (LSP): pep8 rules violation](https://i.ibb.co/rph2V6X/sublime-lsp-pep8-warning.png
 "Sublime Text and Language Server Protocol (LSP): pep8 rules violation")

Remember, that linter settings will be taken from setup.cfg automatically (according to our pyls settings). So rules `D202,D205,D211` will be ignored and max line length will be 99 instead of default 80.

We can setup [mypy](http://mypy-lang.org/) check as well. A corresponding [plugin](https://github.com/tomv564/pyls-mypy) will be needed for that. But it will be better to describe it in a separate article if I can make it. Some non-obvious things exist there as well.

In total, we have a working Python Language Server in Sublime Text 3.
As you can see, the experience wasn't very smooth, but I keep using this code editor, it is my habit.
Yes, I use Pycharm sometimes, it has tons of nice features out of the box. Visual Studio Code editor is good as well, but Sublime looks so native for me.

What conclusion can I make?

- the server doesn't look fully ready (at least implementation in python), have to create PRs and they accepted slowly
- Sublime LSP doesn't work in the right window (_View -> Layout -> Columns: 2_), probably need to fix by submitting further PRs
- it is worth checking the [server implemented by Microsoft](https://github.com/Microsoft/python-language-server/), I think it may be the mainstream.

Meanwhile, my setup is working and it helps me a lot in my daily work.

Thanks to [Grigory Petrov](https://twitter.com/grigoryvp) for his [talk at Moscow Python](http://www.moscowpython.ru/meetup/58/pyre-type-checker/). That was the starting point for me to investigate the LSP world.
