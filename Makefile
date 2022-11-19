.PHONE: build

BASE_PATH ?= /srv/jekyll
SCRIPTS_PATH ?= $(BASE_PATH)/scripts
SCRIPT ?=

build:
	docker build -t st4lk/jekyll:latest .

shell:
	docker run -it --rm st4lk/jekyll:latest bash

bash:
	docker run --rm --volume="$(PWD):$(BASE_PATH)" -it -p 4000:4000 st4lk/jekyll:latest bash

run-script:
	docker run --rm --volume="$(PWD):$(BASE_PATH)" -it -p 4000:4000 st4lk/jekyll:latest bash $(SCRIPTS_PATH)/$(SCRIPT)
