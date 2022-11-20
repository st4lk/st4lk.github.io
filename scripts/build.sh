#!/bin/bash
cd /srv/jekyll/docs

bundle install
bundle exec jekyll build
