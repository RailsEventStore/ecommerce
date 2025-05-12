MUTANT_TARGET_DIRS := app lib

install: ## Installs dependencies, runs migrations, creates db & seeds if necessary
	@bin/setup
	@env RAILS_ENV=test bin/rails db:create

dev:
	@$(MAKE) -j 10 web css

test: ## Run unit tests
	@bin/rails tailwindcss:build
	@echo "Running unit tests"
	@bin/rails test

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

mutate: ## Run mutation tests
ifeq ($(origin MUTANT_NODE_INDEX), environment)
	@echo "Running mutation tests in parallel (Node $$(( $(MUTANT_NODE_INDEX) + 1 ))/$(MUTANT_TOTAL_NODES)) for rails_application"
	@echo "--- DEBUG: Finding potential subject files ---"
	@find $(MUTANT_TARGET_DIRS) -name '*.rb' \
		-not -path '*/test/*' \
		-not -path '*/spec/*' \
		-not -path 'config/*' \
		-not -path '*/initializers/*' \
		-not -path 'db/*' \
		-not -path 'vendor/*' \
		-print > .all_files.tmp
	@echo "--- DEBUG: Found files count: $(shell wc -l < .all_files.tmp)"
	@echo "--- END DEBUG ---"
	@awk "NR % $(MUTANT_TOTAL_NODES) == $(MUTANT_NODE_INDEX)" .all_files.tmp > .node_files.tmp
	@echo "--- DEBUG: Files count for this node ($(MUTANT_NODE_INDEX)): $(shell wc -l < .node_files.tmp)"
	@echo "--- END DEBUG ---"
	@SUBJECT_NAMES_CMD="cat .node_files.tmp | perl -pe 's|^(app|lib)/||; s|\\.rb$$||; s|_([a-z])|uc(\$1)|eg; s|/|::|g; s/(?:^|::)(.)/\\u\$1/g'"
	@echo "--- DEBUG: Attempting to derive subject names for this node... ---"
	@DERIVED_NAMES=$$(eval $$SUBJECT_NAMES_CMD); \
	 EXIT_CODE=$$?; \
	 if [ $$EXIT_CODE -ne 0 ]; then \
	   echo "Perl command failed with exit code $$EXIT_CODE"; \
	   exit $$EXIT_CODE; \
	 elif [ -z "$$DERIVED_NAMES" ]; then \
	   echo "Perl command produced no output."; \
	 else \
	   echo "$$DERIVED_NAMES"; \
	 fi
	@echo "--- END DEBUG ---"
	@SUBJECT_ARGS=$$(echo "$$DERIVED_NAMES" | tr '\\n' ' '); \
	 if [ -z "$$SUBJECT_ARGS" ]; then \
	   echo "No subjects derived for this node. Skipping."; \
	 else \
	   echo "Attempting to run mutant --fail-fast for derived subjects: $$SUBJECT_ARGS"; \
	   RAILS_ENV=test bundle exec mutant --fail-fast run $$SUBJECT_ARGS; \
	 fi
	@rm -f .all_files.tmp .node_files.tmp
else
	@echo "Running mutation tests locally for rails_application (mutant discovers subjects)"
	@RAILS_ENV=test bundle exec mutant run
endif

.PHONY: help test db
.DEFAULT_GOAL := help

css:
	bin/rails tailwindcss:watch[always]

web:
	bin/rails server -p 3000
