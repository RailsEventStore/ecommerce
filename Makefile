bundler: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle install

yarn: ## Install yarn dependencies
	@echo "Installing yarn dependencies"
	@yarn install

install: bundler yarn ## Install all dependencies

migrate: ## Migrate development database
	@echo "Migrating development database"
	@bundle exec rake db:migrate db:test:prepare

db: ## Setup development database
	@echo "Setting up the database"
	@bundle exec rake db:setup

cleanup: ## Clean files which pile up from time to time
	@rm -f log/development.log
	@rm -f log/test.log

dev: install migrate cleanup ## This is an short alias for day to day update of dev's environment

mutate: test ## Run mutation tests
	@bundle exec mutant -j1 --include test --require ./config/environment --use minitest -- 'Ordering*'


test: ## Run unit tests
	@echo "Running unit tests"
	@bundle exec rails t

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help test db
.DEFAULT_GOAL := help

