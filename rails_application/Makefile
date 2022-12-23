install: ## Installs dependencies, runs migrations, creates db & seeds if necessary
	@bin/setup
	@env RAILS_ENV=test bin/rails db:setup

dev:
	@$(MAKE) -j 10 web css worker

mutate: ## Run mutation tests
	@env RAILS_ENV=test bundle exec mutant run

test: ## Run unit tests
	@bin/rails tailwindcss:build
	@echo "Running unit tests"
	@bin/rails test

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help test db
.DEFAULT_GOAL := help

worker:
	bundle exec sidekiq -C config/sidekiq.yml

css:
	bin/rails tailwindcss:watch

web:
	bin/rails server -p 3000
