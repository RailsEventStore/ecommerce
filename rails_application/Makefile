install: ## Installs dependencies, runs migrations, creates db & seeds if necessary
	@bin/setup
	@env RAILS_ENV=test bin/rails db:create

dev:
	@$(MAKE) -j 10 web css

mutate: ## Run mutation tests
	$(eval ACTUAL_MUTANT_ARGS :=)
	$(eval SUBJECTS_TO_RUN := $(strip $(CI_MUTATE_SUBJECTS)))

	@echo "--- Preparing Mutation Test Run ---"
ifeq ($(MUTANT_MODE),incremental)
    ifndef MUTANT_SINCE_TARGET
		$(error MUTANT_MODE is 'incremental', but MUTANT_SINCE_TARGET is not set. This variable should be set by the CI workflow.)
    endif
	$(eval ACTUAL_MUTANT_ARGS := --since $(MUTANT_SINCE_TARGET))
	@echo "Mutation Mode: Incremental"
	@echo "Target for --since: $(MUTANT_SINCE_TARGET)"
else
	@echo "Mutation Mode: Full"
endif

ifeq ($(SUBJECTS_TO_RUN),)
	@echo "Subjects: All relevant (within scope of full/incremental mode)"
else
	@echo "Subjects: Specific group for CI - '$(SUBJECTS_TO_RUN)'"
endif
	@echo "------------------------------------"
	@echo "Executing: env RAILS_ENV=test bundle exec mutant run $(ACTUAL_MUTANT_ARGS) $(SUBJECTS_TO_RUN)"
	@env RAILS_ENV=test bundle exec mutant run $(ACTUAL_MUTANT_ARGS) $(SUBJECTS_TO_RUN)

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
