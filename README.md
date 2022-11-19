Commands
--------

```bash
make build

make bash
```

### Inside docker

```bash
cd /srv/jekyll/mysite

# bundle add webrick

# if you want to start new
jekyll new --skip-bundle .
# modify Gemfile
bundle install

# servie content
bundle exec jekyll serve --host=0.0.0.0
```
