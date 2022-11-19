Developer Articles
==================

https://st4lk.github.io/


Commands
--------

```bash
make build

# do everything manually
make bash

# serve
SCRIPT=serve.sh make run-script
```

### Inside docker (optional)

```bash
cd /srv/jekyll/docs

# bundle add webrick

# if you want to start new
jekyll new --skip-bundle .
# modify Gemfile
bundle install

# servie content
bundle exec jekyll serve --host=0.0.0.0
```
