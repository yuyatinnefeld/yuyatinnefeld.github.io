RUBY_BIN := /opt/homebrew/opt/ruby@3.2/bin
ROOT     := $(CURDIR)
export PATH := $(RUBY_BIN):$(PATH)
export RUBYOPT := -r$(ROOT)/scripts/taint_shim.rb

.PHONY: start stop restart logs

start: stop
	@(cd docs && nohup bundle _2.3.7_ exec jekyll serve --livereload > $(ROOT)/.jekyll.log 2>&1 < /dev/null &)
	@until curl -s -o /dev/null http://localhost:4000/; do sleep 1; done
	@echo "running: http://localhost:4000"

stop:
	-@pkill -f "jekyll serve" && echo "stopped" || echo "not running"

restart: start

logs:
	tail -f $(ROOT)/.jekyll.log
