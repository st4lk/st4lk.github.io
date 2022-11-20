#!/bin/bash
cd /srv/jekyll/source

bundle install
bundle exec jekyll serve --host=0.0.0.0
