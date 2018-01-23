REVEALJS_URL=https://github.com/hakimel/reveal.js/archive/3.6.0.tar.gz
DITAA_URL=https://github.com/stathissideris/ditaa/releases/download/v0.11.0/ditaa-0.11.0-standalone.jar
DIAGRAMS=$(shell ls diagrams/*.txt)

all: reveal.js index.html

ditaa.jar:
	curl -L -o $@ $(DITAA_URL)

reveal.js:
	mkdir -p reveal.js
	curl -L $(REVEALJS_URL) | tar --strip-components=1 -xz -C reveal.js

diagrams/%.svg: diagrams/%.txt ditaa.jar
	java -jar ditaa.jar $< $@ -T --svg

index.html: slides.md $(DIAGRAMS:.txt=.svg)
	pandoc -V theme=simple -V progress=true -V history=true -t revealjs -s -o $@ $<

clean:
	rm -f index.html ditaa.jar
	rm -f diagrams/*.svg 
	rm -rf reveal.js

deps:
	@echo $(DIAGRAMS)
	@echo slides.md

dev:
	live-server &
	make deps | entr make

.PHONY: clean deps