HTML_FILES=$(shell find app -name '*.html')

.jade.html:
	jade --pretty $<

all :: $(HTML_FILES)

.SUFFIXES: .jade .html
