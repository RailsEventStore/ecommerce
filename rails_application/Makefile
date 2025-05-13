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
	 \
	 echo "--- DEBUG: Finding all potential subject files ---"; \
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
	 echo "--- DEBUG: Total potential files found: $$FOUND_COUNT"; \
	 echo "--- END DEBUG (find all files) ---"; \
	 \
	 echo "--- DEBUG: Deriving all subject names from all found files ---"; \
	 cat .all_files.tmp | perl -ne 'next unless /\S/; chomp; s#^(app/(controllers|models|helpers|jobs|mailers|channels|client_panel|read_models|services)|lib)/##; s#\.rb$$##; my @parts = split /\//; my $$result = ""; foreach my $$part (@parts) { next unless $$part; $$part =~ s#_([a-z])#uc($$1)#eg; $$result .= ucfirst($$part) . "::"; } $$result =~ s/::$$//; print "$$result\n" if $$result && $$result !~ /^::/' > .all_derived_names.tmp; \
	 PERL_EXIT_CODE_ALL=$$?; \
	 if [ $$PERL_EXIT_CODE_ALL -ne 0 ]; then \
	   echo "ERROR: Perl command for all names failed with exit code $$PERL_EXIT_CODE_ALL"; \
	 elif [ ! -s .all_derived_names.tmp ] && [ "$$FOUND_COUNT" -gt 0 ]; then \
	   echo "WARN: Perl command for all names produced no output, but files exist."; \
	 elif [ ! -s .all_derived_names.tmp ]; then \
	   echo "Perl command for all names produced no output (expected if no files found)."; \
	 else \
	   echo "--- DEBUG: All derived names (before subject filter, from .all_derived_names.tmp): ---"; \
	   head -n 20 .all_derived_names.tmp; \
	 fi; \
	 echo "--- END DEBUG (perl for all names) ---"; \
	 \
	 echo "--- DEBUG: Filtering all derived names based on .mutant.yml 'subjects' patterns ---"; \
	 SUBJECT_PATTERNS_RAILS_APP='^(Orders::|ClientOrders::)'; \
	 if [ -f .all_derived_names.tmp ]; then \
	   grep -E "$$SUBJECT_PATTERNS_RAILS_APP" .all_derived_names.tmp > .ci_total_filtered_subjects.tmp || true; \
	 else \
	   touch .ci_total_filtered_subjects.tmp; \
	 fi; \
	 CI_TOTAL_FILTERED_COUNT=$$(cat .ci_total_filtered_subjects.tmp | wc -l); \
	 echo "--- DEBUG: Total filtered subjects for CI count: $$CI_TOTAL_FILTERED_COUNT"; \
	 echo "--- DEBUG: Total filtered subjects for CI (from .ci_total_filtered_subjects.tmp, first 20 lines): ---"; \
	 head -n 20 .ci_total_filtered_subjects.tmp || echo "File .ci_total_filtered_subjects.tmp is empty."; \
	 echo "--- END DEBUG (total CI filtered subjects) ---"; \
	 \
	 echo "--- DEBUG: Dividing filtered subjects for this node ($(MUTANT_NODE_INDEX)) ---"; \
	 awk "NR % $(MUTANT_TOTAL_NODES) == $(MUTANT_NODE_INDEX)" .ci_total_filtered_subjects.tmp > .node_subjects_to_run.tmp; \
	 if [ $$? -ne 0 ]; then echo "ERROR: awk for node subjects failed!"; exit 1; fi; \
	 NODE_SUBJECTS_TO_RUN_COUNT=$$(cat .node_subjects_to_run.tmp | wc -l); \
	 echo "--- DEBUG: Subjects for this node count: $$NODE_SUBJECTS_TO_RUN_COUNT"; \
	 echo "--- DEBUG: Subjects for this node (from .node_subjects_to_run.tmp, first 10 lines): ---"; \
	 head -n 10 .node_subjects_to_run.tmp || echo "File .node_subjects_to_run.tmp is empty."; \
	 echo "--- END DEBUG (node subjects to run) ---"; \
	 \
	 SUBJECT_ARGS=$$(cat .node_subjects_to_run.tmp | xargs); \
	 echo "--- DEBUG: SUBJECT_ARGS for mutant for this node: [$$SUBJECT_ARGS]"; \
	 \
	 if [ -z "$$SUBJECT_ARGS" ]; then \
	   echo "No subjects matching 'subjects' criteria found for this node. Skipping."; \
	 else \
	   echo "Attempting to run mutant for filtered subjects for this node: $$SUBJECT_ARGS"; \
	   RAILS_ENV=test bundle exec mutant run $$SUBJECT_ARGS; \
	   MUTANT_EXIT_CODE=$$?; \
	   if [ $$MUTANT_EXIT_CODE -ne 0 ]; then \
	     echo "ERROR: mutant run failed with exit code $$MUTANT_EXIT_CODE"; \
	     exit $$MUTANT_EXIT_CODE; \
	   fi; \
	 fi; \
	 rm -f .all_files.tmp .all_derived_names.tmp .ci_total_filtered_subjects.tmp .node_subjects_to_run.tmp .node_files_for_derivation.tmp .derived_names_for_node.tmp .filtered_node_subjects.tmp
else
	@echo "Running mutation tests locally for rails_application (mutant uses .mutant.yml directly)"
	@echo "'--- DEBUG: Total filtered subjects for CI (from .ci_total_filtered_subjects.tmp, first 20 lines): ---'"
	@(RAILS_ENV=test bundle exec mutant run); \
	MUTANT_LOCAL_EXIT_CODE=$$?; \
	echo "Local mutant run finished with exit code: $$MUTANT_LOCAL_EXIT_CODE"; \
	exit $$MUTANT_LOCAL_EXIT_CODE
endif

.PHONY: help test db
.DEFAULT_GOAL := help

css:
	bin/rails tailwindcss:watch[always]

web:
	bin/rails server -p 3000
