#!/bin/bash
cd /srv/jekyll/source

bundle install
JEKYLL_ENV=production bundle exec jekyll build

echo "Clearing docs folder"
cd ..
rm -rf docs/

echo "Copying _site to docs"
cp -R source/_site docs
# tell github to not build with jekyll, we are doing it by ourselfes
touch docs/.nojekyll
