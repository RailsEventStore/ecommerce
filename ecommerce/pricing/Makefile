install:
	@bundle install

test:
	@bundle exec ruby -e "require \"rake/rake_test_loader\"" test/*_test.rb

MUTANT_TARGET_DIRS := lib

mutate:
ifeq ($(origin MUTANT_NODE_INDEX), environment)
	@echo "Running mutation tests in parallel (Node $(MUTANT_NODE_INDEX)/$(MUTANT_TOTAL_NODES)) for pricing, using .mutant.yml"
	@find $(MUTANT_TARGET_DIRS) -path ./vendor -prune -o -name '*.rb' -print | sed 's|^\./||' > .all_files.tmp
	@awk "NR % $(MUTANT_TOTAL_NODES) == $(MUTANT_NODE_INDEX)" .all_files.tmp > .node_files.tmp
	@SUBJECT_NAMES_CMD="cat .node_files.tmp | perl -pe 's|^lib/||; s|\\.rb$$||; s|/|::|g; s/\\b(\\w)/ucfirst(\$1)/ge'"
	@SUBJECT_ARGS=$$($$SUBJECT_NAMES_CMD | tr '\\n' ' '); \
	 if [ -z "$$SUBJECT_ARGS" ]; then \
	   echo "No subjects derived for this node. Skipping."; \
	 else \
	   echo "Attempting to run mutant --fail-fast for derived subjects: $$SUBJECT_ARGS"; \
	   RAILS_ENV=test bundle exec mutant --fail-fast run $$SUBJECT_ARGS; \
	 fi
	@rm -f .all_files.tmp .node_files.tmp
else
	@echo "Running mutation tests locally (using .mutant.yml)"
	@RAILS_ENV=test bundle exec mutant run
endif

.PHONY: install test mutate
