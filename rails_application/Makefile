install: ## Installs dependencies, runs migrations, creates db & seeds if necessary
	@bin/setup
	@env RAILS_ENV=test bin/rails db:create

dev:
	@$(MAKE) -j 10 web css

mutate: ## Run mutation tests
ifeq ($(CI_MUTATE_SUBJECTS),)
	@echo "Running all mutation tests (local or full CI run)"
	@env RAILS_ENV=test bundle exec mutant run
else
	@echo "Running CI mutation tests for subjects: $(CI_MUTATE_SUBJECTS)"
	@env RAILS_ENV=test bundle exec mutant run $(CI_MUTATE_SUBJECTS)
endif

test: ## Run unit tests
	@bin/rails tailwindcss:build
	@echo "Running unit tests"
	@bin/rails test

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help test db
.DEFAULT_GOAL := help

css:
	bin/rails tailwindcss:watch[always]

web:
	bin/rails server -p 3000
