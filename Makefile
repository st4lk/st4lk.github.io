.PHONE: build

BASE_PATH ?= /srv/jekyll
SCRIPTS_PATH ?= $(BASE_PATH)/scripts
LABS_TARGET_PATH ?= source/travel/labs
WAHOO_POINTS_PATH ?= labs_source/wahoo-points
IMAGE_GEO_TAGS_PATH ?= labs_source/image-geo-tags
SCRIPT ?=

build:
	docker build -t st4lk/jekyll:latest .

shell:
	docker run -it --rm st4lk/jekyll:latest bash

bash:
	docker run --rm --volume="$(PWD):$(BASE_PATH)" -it -p 4000:4000 st4lk/jekyll:latest bash

run-script:
	docker run --rm --volume="$(PWD):$(BASE_PATH)" -it -p 4000:4000 st4lk/jekyll:latest bash $(SCRIPTS_PATH)/$(SCRIPT)

refresh-labs:
	git submodule foreach git pull origin main

build-labs: refresh-labs wahoo-build-and-copy image-geo-tags-build-and-copy

wahoo-points-build:
	cd $(WAHOO_POINTS_PATH) && make install && make build-prod

wahoo-points-copy:
	rm -rf $(LABS_TARGET_PATH)/wahoo-points/app/
	cp -r $(WAHOO_POINTS_PATH)/dist $(LABS_TARGET_PATH)/wahoo-points/
	mv $(LABS_TARGET_PATH)/wahoo-points/dist $(LABS_TARGET_PATH)/wahoo-points/app
	sed -i '' -e 's/\/assets\//app\/assets\//g' $(LABS_TARGET_PATH)/wahoo-points/app/index.html

wahoo-build-and-copy: wahoo-points-build wahoo-points-copy

image-geo-tags-build:
	cd $(IMAGE_GEO_TAGS_PATH) && make install && make build-prod

image-geo-tags-copy:
	rm -rf $(LABS_TARGET_PATH)/image-geo-tags/app/
	cp -r $(IMAGE_GEO_TAGS_PATH)/dist $(LABS_TARGET_PATH)/image-geo-tags/
	mv $(LABS_TARGET_PATH)/image-geo-tags/dist $(LABS_TARGET_PATH)/image-geo-tags/app
	sed -i '' -e 's/\/assets\//app\/assets\//g' $(LABS_TARGET_PATH)/image-geo-tags/app/index.html

image-geo-tags-build-and-copy: image-geo-tags-build image-geo-tags-copy
