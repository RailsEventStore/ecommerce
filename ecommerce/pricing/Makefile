GIT_BASE_SHA ?= $(shell git merge-base HEAD origin/master)

install:
	@bundle install

test:
	@bundle exec ruby -e "require 'rake/rake_test_loader'" test/*_test.rb

mutate: ## Run full mutation tests
	@echo "Running full mutation tests..."
	@RUBYOPT="-Ilib -Itest" bundle exec mutant run 'Pricing*'

mutate-changes: ## Run incremental mutation tests on changes
	@echo "Running incremental mutation tests against $(GIT_BASE_SHA)..."
	@RUBYOPT="-Ilib -Itest" bundle exec mutant run --since $(GIT_BASE_SHA) 'Pricing*'

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%%-30s\033[0m %%s\n", $$1, $$2}'

.PHONY: install test mutate mutate-changes help
.DEFAULT_GOAL := help
