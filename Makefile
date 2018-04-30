ifneq ($(wildcard ../ingy-npm),)
    include ../ingy-npm/share/ingy-npm.mk
else
    $(warning Error: ../ingy-npm does not exist)
    $(warning Try: git clone git@github.com:ingydotnet/ingy-npm ../ingy-npm)
    $(error Fix your errors)
endif

test: node_modules
	coffee -e '(require "./test/lib/test/harness").run()' $@/*.coffee

clean: ingy-npm-clean
