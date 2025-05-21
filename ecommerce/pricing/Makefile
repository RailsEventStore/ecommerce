install:
	@bundle install

test:
	@echo "Running unit tests for pricing"
	@bundle exec ruby -e "require \"rake/rake_test_loader\"" test/*_test.rb

mutate:
	$(eval ACTUAL_MUTANT_ARGS :=)
	$(eval SUBJECTS_TO_RUN := $(strip $(CI_MUTATE_SUBJECTS)))

	@echo "--- Preparing Mutation Test Run for pricing ---"
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
	@echo "Executing: bundle exec mutant run $(ACTUAL_MUTANT_ARGS) $(SUBJECTS_TO_RUN)"
	@bundle exec mutant run $(ACTUAL_MUTANT_ARGS) $(SUBJECTS_TO_RUN)

.PHONY: install test mutate
