REVEALJS_URL=https://github.com/hakimel/reveal.js/archive/3.6.0.tar.gz
DITAA_URL=https://github.com/stathissideris/ditaa/releases/download/v0.11.0/ditaa-0.11.0-standalone.jar
DIAGRAMS=$(shell ls diagrams/*.txt)
PLOTS=$(shell ls plots/*.R)
EXAMPLES=$(shell ls examples/*.R)
SCREENSHOTS=$(shell ls screenshots/*.png)

all: reveal.js index.html

ditaa.jar:
	curl -L -o $@ $(DITAA_URL)

reveal.js:
	mkdir -p reveal.js
	curl -L $(REVEALJS_URL) | tar --strip-components=1 -xz -C reveal.js

diagrams/%.svg: diagrams/%.txt ditaa.jar
	java -jar ditaa.jar $< $@ -T --svg

plots/%.png: plots/%.R
	Rscript -e "png('$@');source('$<');dev.off()"

slides.md: slides.md.m4 $(DIAGRAMS:.txt=.svg) $(EXAMPLES) $(PLOTS) $(PLOTS:.R=.png) $(SCREENSHOTS)
	m4 $< > $@

index.html: slides.md
	pandoc -V theme=simple -V progress=true -V history=true -t revealjs -s -o $@ $<

clean:
	rm -f index.html ditaa.jar
	rm -f diagrams/*.svg 
	rm -f plots/*.svg 
	rm -rf reveal.js

dev:
	bash -c "while :; do make; if [[ $$? == 0 ]]; then sleep 1; fi; done"

.PHONY: clean dev