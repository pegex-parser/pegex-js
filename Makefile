INGY_NPM := ../ingy-npm

ifneq ($(wildcard $(INGY_NPM)),)
    include ../ingy-npm/share/ingy-npm.mk
else
    $(warning Error: $(INGY_NPM) does not exist)
    $(warning Try: git clone git@github.com:ingydotnet/ingy-npm $(INGY_NPM))
    $(error Fix your errors)
endif

test: node_modules
	coffee -e '(require "./test/lib/test/harness").run()' $@/*.coffee

clean: ingy-npm-clean
