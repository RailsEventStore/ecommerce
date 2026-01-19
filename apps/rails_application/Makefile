GIT_BASE_SHA ?= $(shell git merge-base HEAD origin/master)

install: ## Installs dependencies, runs migrations, creates db & seeds if necessary
	@bin/setup

dev:
	@$(MAKE) -j 2 web css

build-tailwind:
	@echo "Building Tailwind CSS..."
	@bin/rails tailwindcss:build

mutate: build-tailwind
ifdef MUTANT_SUBJECT
	@echo "Running mutation tests for subject: '$(MUTANT_SUBJECT)'"
	@bundle exec mutant run $(MUTANT_OPTS) -- '$(MUTANT_SUBJECT)'
else
	@echo "Running full mutation tests..."
	@bundle exec mutant run $(MUTANT_OPTS)
endif

mutate-changes: ## Run incremental mutation tests on changes
	@echo "Running incremental mutation tests against $(GIT_BASE_SHA)..."
	@RAILS_ENV=test bundle exec mutant run --since $(GIT_BASE_SHA)

test: build-tailwind
	@echo "Running unit tests..."
	@BROWSERSLIST_IGNORE_OLD_DATA=1 bin/rails test

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

css:
	@bin/rails tailwindcss:watch[always]

web:
	@bin/rails server -p 3000

test-mutant-runner: build-tailwind
	@RAILS_ENV=test bundle exec mutant test -j 4

.PHONY: help install dev build-tailwind test mutate mutate-changes css web test-mutant-runner
.DEFAULT_GOAL := help
