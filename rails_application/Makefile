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
	 echo "--- DEBUG: Checking target directories [$(MUTANT_TARGET_DIRS)] ---"; \
	 ls -ld $(MUTANT_TARGET_DIRS) || (echo "ERROR: Target directories not found!" && exit 1); \
	 echo "--- DEBUG: Finding potential subject files ---"; \
	 find $(MUTANT_TARGET_DIRS) -name '*.rb' \
		-not -path '*/test/*' \
		-not -path '*/spec/*' \
		-not -path 'config/*' \
		-not -path '*/initializers/*' \
		-not -path 'db/*' \
		-not -path 'vendor/*' \
		-print > .all_files.tmp; \
	 if [ $$? -ne 0 ]; then echo "ERROR: find command failed!"; exit 1; fi; \
	 FOUND_COUNT=$$(cat .all_files.tmp | wc -l); \
	 echo "--- DEBUG: Found files count: $$FOUND_COUNT"; \
	 echo "--- DEBUG: Content of .all_files.tmp (first 5 lines): ---"; \
	 head -n 5 .all_files.tmp || echo "File .all_files.tmp is empty."; \
	 echo "--- END DEBUG (find) ---"; \
	 echo "--- DEBUG: Running awk to create .node_files.tmp ---"; \
	 awk "NR % $(MUTANT_TOTAL_NODES) == $(MUTANT_NODE_INDEX)" .all_files.tmp > .node_files.tmp; \
	 if [ $$? -ne 0 ]; then echo "ERROR: awk command failed!"; exit 1; fi; \
	 NODE_COUNT=$$(cat .node_files.tmp | wc -l); \
	 echo "--- DEBUG: Files count for this node ($(MUTANT_NODE_INDEX)): $$NODE_COUNT"; \
	 echo "--- DEBUG: Content of .node_files.tmp (first 5 lines): ---"; \
	 head -n 5 .node_files.tmp || echo "File .node_files.tmp is empty."; \
	 echo "--- END DEBUG (awk) ---"; \
	 echo "--- DEBUG: Attempting to derive subject names for this node... ---"; \
	 DERIVED_NAMES=$$(cat .node_files.tmp | perl -ne 'next unless /\S/; chomp; s#^(app/(controllers|models|helpers|jobs|mailers|channels|client_panel|read_models|services)|lib)/##; s#\.rb$$##; my @parts = split /\//; my $$result = ""; foreach my $$part (@parts) { next unless $$part; $$part =~ s#_([a-z])#uc($$1)#eg; $$result .= ucfirst($$part) . "::"; } $$result =~ s/::$$//; print "$$result\n" if $$result && $$result !~ /^::/'); \
	 PERL_EXIT_CODE=$$?; \
	 if [ $$PERL_EXIT_CODE -ne 0 ]; then \
	   echo "ERROR: Perl command failed with exit code $$PERL_EXIT_CODE"; \
	 elif [ -z "$$DERIVED_NAMES" ] && [ "$$NODE_COUNT" -gt 0 ]; then \
	   echo "WARN: Perl command produced no output, but node files exist."; \
	 elif [ -z "$$DERIVED_NAMES" ]; then \
	   echo "Perl command produced no output (expected if no files for node)."; \
	 else \
	   echo "--- DEBUG: Derived names (before subject filter): ---"; \
	   echo "$$DERIVED_NAMES"; \
	 fi; \
	 echo "--- END DEBUG (perl) ---"; \
	 SUBJECT_PATTERNS_RAILS_APP='^(Orders::|ClientOrders::)'; \
	 FILTERED_NAMES=$$(echo "$$DERIVED_NAMES" | grep -E "$$SUBJECT_PATTERNS_RAILS_APP" || true); \
	 echo "--- DEBUG: Filtered names (after subject filter to modules): ---"; \
	 echo "$$FILTERED_NAMES"; \
	 SUBJECT_ARGS=$$(echo "$$FILTERED_NAMES" | xargs); \
	 if [ -z "$$SUBJECT_ARGS" ]; then \
	   echo "No subjects matching module criteria (Orders::*, ClientOrders::*) found for this node. Skipping."; \
	 else \
	   echo "Attempting to run mutant for filtered subjects: $$SUBJECT_ARGS"; \
	   RAILS_ENV=test bundle exec mutant run $$SUBJECT_ARGS; \
	   MUTANT_EXIT_CODE=$$?; \
	   if [ $$MUTANT_EXIT_CODE -ne 0 ]; then \
	     echo "ERROR: mutant run failed with exit code $$MUTANT_EXIT_CODE"; \
	     exit $$MUTANT_EXIT_CODE; \
	   fi; \
	 fi; \
	 rm -f .all_files.tmp .node_files.tmp
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
