---
layout: post
title:  "Debug django project with embedded python debugger pdb"
date:   2012-11-18 18:19:43 +0000
categories: django python sublime
redirect_from:
  - /2012/debug-django-project-embedded-python-debugger-pdb/
  - /blog/2012/11/18/debug-django-project-embedded-python-debugger-pdb.html
---

I use [sublime-text](http://www.sublimetext.com/) as code editor. It doesn't have a debugger, so to debug django projects i often used

```python
print var_name
```

and look for output in local development server console. I use this approach today also, but sometimes it is great to run code step by step to see variables at each step.

It can be done with embedded python debugger pdb:

```python
import pdb; pdb.set_trace()
```

<!--more-->

I.e. we put this line in needed place of code, where we want so stop. It is a breakpoint. Now refresh project page in browser. When project code will reach this line, browser will hang and in console we'll see:

```python
(Pdb)
```

We now inside debugger and can input [commands](http://docs.python.org/2/library/pdb.html#debugger-commands), for example these:

- l - (list), look the source code
- n - (step next) step to next line without entering inside function
- s - (step in) step inside to next line, i.e. if we are standing at function call, we'll go inside this function
- r - (step out) step to first line after current block of code. For example, if current line is inside cycle and `r` is pressed, next line will be first line after this cycle.
- c - (continue) continue until next breakpoint, i.e. until `pdb.set_trace()`
- p - (print) execude python code or just show variable: `p var_name`

## Example

Suppose we have such a view:

![view](/assets/images/posts/2012-11-18-debug-django-project-embedded-python-debugger-pdb/view.jpeg "view")

Insert `import pdb; pdb.set_trace()` in needed place and run dev server, if it not already started:

![view_pdb](/assets/images/posts/2012-11-18-debug-django-project-embedded-python-debugger-pdb/view_pdb.jpeg "view_pdb")

In browser access the page, that calls this view. The page will hang:

![browser_hang](/assets/images/posts/2012-11-18-debug-django-project-embedded-python-debugger-pdb/browser_hang.jpeg "browser_hang")

In console we see (Pdb):

![pdb_console](/assets/images/posts/2012-11-18-debug-django-project-embedded-python-debugger-pdb/pdb_console.jpeg "pdb_console")

Lets look, where we now by command `l`:

![pdb_l](/assets/images/posts/2012-11-18-debug-django-project-embedded-python-debugger-pdb/pdb_l.jpeg "pdb_l")

Make two next steps with `n`:

![pdb_nn](/assets/images/posts/2012-11-18-debug-django-project-embedded-python-debugger-pdb/pdb_nn.jpeg "pdb_nn")

Look value of variables `about` and `about.content`:

![pdb_p](/assets/images/posts/2012-11-18-debug-django-project-embedded-python-debugger-pdb/pdb_p.jpeg "pdb_p")

Continue with `c`:

![pdb_c](/assets/images/posts/2012-11-18-debug-django-project-embedded-python-debugger-pdb/pdb_c.jpeg "pdb_c")

Page is shown in browser:

![browser_done](/assets/images/posts/2012-11-18-debug-django-project-embedded-python-debugger-pdb/browser_done.jpeg "browser_done")
