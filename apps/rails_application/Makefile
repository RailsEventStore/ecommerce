install: ## Installs dependencies, runs migrations, creates db & seeds if necessary
	@bin/setup

dev: ## Start development environment with web server and CSS watcher
	@$(MAKE) -j 2 web css

TAILWIND_SRC    := app/assets/stylesheets/application.tailwind.css
TAILWIND_CONFIG := config/tailwind.config.js
TAILWIND_BUILD  := app/assets/builds
TAILWIND_OUT    := $(TAILWIND_BUILD)/tailwind.css

$(TAILWIND_OUT): $(TAILWIND_SRC) $(TAILWIND_CONFIG) | $(TAILWIND_BUILD)
	@echo "Building Tailwind CSS…"
	@bin/rails tailwindcss:build

$(TAILWIND_BUILD):
	mkdir -p $(TAILWIND_BUILD)

tailwind: $(TAILWIND_OUT) ## Build Tailwind CSS

mutate: tailwind ## Run mutation tests. Narrow to MUTANT_SUBJECT if set. Use MUTANT_OPTS for additional mutant options.
ifdef MUTANT_SUBJECT
	@echo "Running mutation tests for subject: '$(MUTANT_SUBJECT)'"
	@bundle exec mutant run $(MUTANT_OPTS) -- '$(MUTANT_SUBJECT)'
else
	@echo "Running full mutation tests..."
	@bundle exec mutant run $(MUTANT_OPTS)
endif

GIT_BASE_SHA ?= $(shell git merge-base HEAD origin/master)

mutate-changes: ## Run incremental mutation tests on changes
	@echo "Running incremental mutation tests against $(GIT_BASE_SHA)..."
	@RAILS_ENV=test bundle exec mutant run --since $(GIT_BASE_SHA)

test: ## Run all tests
	@echo "Running all tests..."
	@BROWSERSLIST_IGNORE_OLD_DATA=1 bin/rails test

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

css:
	@bin/rails tailwindcss:watch[always]

web:
	@bin/rails server -p 3000

test-mutant-runner: tailwind ## Run tests with parallel jobs using mutant test runner. Use MUTANT_OPTS for additional mutant options.
	@RAILS_ENV=test bundle exec mutant test $(MUTANT_OPTS)

.PHONY: help install dev build-tailwind test mutate mutate-changes css web test-mutant-runner
.DEFAULT_GOAL := help
