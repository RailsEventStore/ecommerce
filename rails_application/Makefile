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
	@NODE_DISPLAY_INDEX=$$(( $(MUTANT_NODE_INDEX) + 1 )); \
	 echo "Running mutation tests in parallel (Node $$NODE_DISPLAY_INDEX/$(MUTANT_TOTAL_NODES)) for rails_application"; \
	 \
	 echo "--- DEBUG: Generating canonical list of subjects from .mutant.yml using 'mutant util subjects' ---"; \
	 RAILS_ENV=test bundle exec mutant util subjects > .canonical_subjects.tmp; \
	 if [ $$? -ne 0 ]; then echo "ERROR: 'mutant util subjects' failed!"; exit 1; fi; \
	 CANONICAL_COUNT=$$(cat .canonical_subjects.tmp | wc -l); \
	 echo "--- DEBUG: Canonical subjects count (from mutant util subjects): $$CANONICAL_COUNT"; \
	 echo "--- DEBUG: Content of .canonical_subjects.tmp (first 10 lines): ---"; \
	 head -n 10 .canonical_subjects.tmp || echo "File .canonical_subjects.tmp is empty."; \
	 echo "--- END DEBUG (canonical subjects) ---"; \
	 \
	 echo "--- DEBUG: Dividing canonical subjects for this node ($(MUTANT_NODE_INDEX)) ---"; \
	 awk "NR % $(MUTANT_TOTAL_NODES) == $(MUTANT_NODE_INDEX)" .canonical_subjects.tmp > .node_subjects.tmp; \
	 if [ $$? -ne 0 ]; then echo "ERROR: awk command failed to divide subjects!"; exit 1; fi; \
	 NODE_SUBJECT_COUNT=$$(cat .node_subjects.tmp | wc -l); \
	 echo "--- DEBUG: Subjects for this node count: $$NODE_SUBJECT_COUNT"; \
	 echo "--- DEBUG: Content of .node_subjects.tmp (first 10 lines): ---"; \
	 head -n 10 .node_subjects.tmp || echo "File .node_subjects.tmp is empty."; \
	 echo "--- END DEBUG (node subjects) ---"; \
	 \
	 SUBJECT_ARGS=$$(cat .node_subjects.tmp | xargs); \
	 echo "--- DEBUG: SUBJECT_ARGS for mutant: [$$SUBJECT_ARGS]"; \
	 \
	 if [ -z "$$SUBJECT_ARGS" ]; then \
	   echo "No subjects assigned to this node. Skipping."; \
	 else \
	   echo "Attempting to run mutant for subjects: $$SUBJECT_ARGS"; \
	   RAILS_ENV=test bundle exec mutant run $$SUBJECT_ARGS; \
	   MUTANT_EXIT_CODE=$$?; \
	   if [ $$MUTANT_EXIT_CODE -ne 0 ]; then \
	     echo "ERROR: mutant run failed with exit code $$MUTANT_EXIT_CODE"; \
	     exit $$MUTANT_EXIT_CODE; \
	   fi; \
	 fi; \
	 rm -f .canonical_subjects.tmp .node_subjects.tmp .all_files.tmp .derived_names.tmp .filtered_names.tmp # Clean up all potential temp files
else
	@echo "Running mutation tests locally for rails_application (mutant discovers subjects from .mutant.yml)"
	@RAILS_ENV=test bundle exec mutant run
endif

.PHONY: help test db
.DEFAULT_GOAL := help

css:
	bin/rails tailwindcss:watch[always]

web:
	bin/rails server -p 3000
