Developer Articles
==================

https://st4lk.github.io/

Served thanks to [github pages](https://pages.github.com/).

For multi language support [jekyll-multiple-languages-plugin](https://github.com/kurtsson/jekyll-multiple-languages-plugin#4-configuration) is used.


Commands
--------

```bash
# build docker image
make build

# do everything manually
make bash

# serve the site on http://localhost:4000
SCRIPT=serve.sh make run-script

# build the site
SCRIPT=build.sh make run-script
```

### Inside docker (optional)

```bash
cd /srv/jekyll/source
bundle install

# serve content
bundle exec jekyll serve --host=0.0.0.0

# location of default templates
bundle info --path minima
```


For the first time:
```bash
jekyll new --skip-bundle .
# modify Gemfile as written in github docs
```
