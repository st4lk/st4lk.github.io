#!/bin/bash
cd /srv/jekyll/docs

bundle install
bundle exec jekyll serve --host=0.0.0.0
