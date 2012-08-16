HTML_FILES=$(shell find app -name '*.html')
JS_FILES=src/app.js src/main.js

.jade.html:
	jade --pretty $<

.ls.js:
	env PATH="$$PATH:./node_modules/LiveScript/bin" livescript -c  $<

all :: $(HTML_FILES) $(JS_FILES)

run :: all
	node src/app.js

.SUFFIXES: .jade .html .ls .js
