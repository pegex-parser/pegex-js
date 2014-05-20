.PHONY: npm doc test

NAME := $(shell grep '^name: ' Meta 2>/dev/null | cut -d' ' -f2)
VERSION := $(shell grep '^version: ' Meta 2>/dev/null | cut -d' ' -f2)
DISTDIR := $(NAME)-$(VERSION)
DIST := $(DISTDIR).tar.gz

ALL_LIB_DIR := $(shell find lib -type d)
ALL_NPM_DIR := $(ALL_LIB_DIR:%=npm/%)
ALL_COFFEE := $(shell find lib -name *.coffee)
ALL_NPM_JS := $(ALL_COFFEE:%.coffee=npm/%.js)

default: help

help:
	@echo ''
	@echo 'Makefile targets:'
	@echo ''
	@echo '    make test     - Run the repo tests'
	@echo '    make install  - Install the repo'
	@echo '    make doc      - Make the docs'
	@echo ''
	@echo '    make npm      - Make npm/ dir for Node'
	@echo '    make dist     - Make NPM distribution tarball'
	@echo '    make distdir  - Make NPM distribution directory'
	@echo '    make disttest - Run the dist tests'
	@echo '    make publish  - Publish the dist to NPM'
	@echo '    make publish-dryrun   - Don'"'"'t actually push to NPM'
	@echo ''
	@echo '    make upgrade  - Upgrade the build system'
	@echo '    make clean    - Clean up build files'
	@echo ''

test:
	coffee -e '(require "./test/lib/test/harness").run()' $@

install: distdir
	(cd $(DISTDIR); npm install -g .)
	make clean

doc:
	kwim --complete --wrap doc/$(NAME).kwim > ReadMe.pod

npm:
	./.pkg/bin/make-npm

dist: clean npm
	(cd npm; dzil build)
	mv npm/$(DIST) .
	rm -fr npm

distdir: clean npm
	(cd npm; dzil build)
	mv npm/$(DIST) .
	tar xzf $(DIST)
	rm -fr npm $(DIST)

disttest: npm
	(cd npm; dzil test) && rm -fr npm

publish: check-release dist
	npm publish $(DIST)
	git tag $(VERSION)
	git push --tag
	rm $(DIST)

publish-dryrun: check-release dist
	echo npm publish $(DIST)
	echo git tag $(VERSION)
	echo git push --tag
	rm $(DIST)

clean purge:
	rm -fr name $(DIST) $(DISTDIR)

upgrade:
	(PKGREPO=$(PWD) make -C ../javascript-pkg do-upgrade)

#------------------------------------------------------------------------------
check-release:
	./.pkg/bin/check-release

do-upgrade:
	mkdir -p $(PKGREPO)/.pkg/bin
	cp Makefile $(PKGREPO)/Makefile
	cp -r bin/* $(PKGREPO)/.pkg/bin/
