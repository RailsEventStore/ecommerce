install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle install

mutate: test ## Run mutation tests
	@bundle exec mutant -j1 --include test --require ./config/environment --use minitest -- 'Ordering*'


test: ## Run unit tests
	@echo "Running unit tests"
	@bundle exec rails t

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help test
.DEFAULT_GOAL := help

