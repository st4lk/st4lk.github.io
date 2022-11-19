.PHONE: build

build:
	docker build -t st4lk/jekyll:latest .

shell:
	docker run -it --rm st4lk/jekyll:latest bash

bash:
	docker run --rm --volume="$PWD:/srv/jekyll" -it -p 4000:4000 st4lk/jekyll:latest bash
