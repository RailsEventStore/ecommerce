MUTANT_MODE_INTERNAL := $(PASSED_MODE)
MUTANT_SINCE_TARGET_INTERNAL := $(PASSED_SINCE_TARGET)

install:
	@bundle install

test:
	@echo "Running unit tests for pricing"
	@bundle exec ruby -e "require \"rake/rake_test_loader\"" test/*_test.rb

mutate:
	@echo "--- Makefile Debug: Initial State ---"
	@echo "PASSED_MODE (from CLI):                  '$(PASSED_MODE)'"
	@echo "PASSED_SINCE_TARGET (from CLI):          '$(PASSED_SINCE_TARGET)'"
	@echo "CI_MUTATE_SUBJECTS (from environment):   '$(CI_MUTATE_SUBJECTS)'"

	@echo "--- Makefile Debug: After Internal Assignment ---"
	@echo "MUTANT_MODE_INTERNAL (after assign):     '$(MUTANT_MODE_INTERNAL)'"
	@echo "MUTANT_SINCE_TARGET_INTERNAL (after assign):'$(MUTANT_SINCE_TARGET_INTERNAL)'"

	$(eval SUBJECTS_TO_RUN := $(strip $(CI_MUTATE_SUBJECTS)))
	$(eval TEMP_ACTUAL_MUTANT_ARGS :=)

	@echo "--- Preparing Mutation Test Run for pricing ---"
ifeq ($(MUTANT_MODE_INTERNAL),incremental)
	@echo "  Conditional: MUTANT_MODE_INTERNAL is 'incremental'."
	ifndef MUTANT_SINCE_TARGET_INTERNAL
		$(error FATAL ERROR (Makefile): MUTANT_MODE_INTERNAL ('$(MUTANT_MODE_INTERNAL)') is incremental, but MUTANT_SINCE_TARGET_INTERNAL is NOT DEFINED. PASSED_SINCE_TARGET was '$(PASSED_SINCE_TARGET)'.)
	endif
	ifeq ($(strip $(MUTANT_SINCE_TARGET_INTERNAL)),)
		$(error FATAL ERROR (Makefile): MUTANT_MODE_INTERNAL ('$(MUTANT_MODE_INTERNAL)') is incremental, but MUTANT_SINCE_TARGET_INTERNAL IS EMPTY. PASSED_SINCE_TARGET was '$(PASSED_SINCE_TARGET)', internal value was '[$(MUTANT_SINCE_TARGET_INTERNAL)]'.)
	endif

	@echo "  MUTANT_SINCE_TARGET_INTERNAL appears to be set and non-empty: '[$(MUTANT_SINCE_TARGET_INTERNAL)]'"
	$(eval TEMP_ACTUAL_MUTANT_ARGS := --since $(MUTANT_SINCE_TARGET_INTERNAL))
	@echo "  Action: Set for Incremental Mutation."
	@echo "  Target for --since: '$(MUTANT_SINCE_TARGET_INTERNAL)'"
else
	@echo "  Conditional: MUTANT_MODE_INTERNAL is NOT 'incremental' (actual value: '$(MUTANT_MODE_INTERNAL)'). Setting for Full Mutation."
endif

	@echo "  Final TEMP_ACTUAL_MUTANT_ARGS: '$(TEMP_ACTUAL_MUTANT_ARGS)'"
ifeq ($(SUBJECTS_TO_RUN),)
	@echo "  Subjects: All relevant (within scope of full/incremental mode)"
else
	@echo "  Subjects: Specific group for CI - '$(SUBJECTS_TO_RUN)'" 
endif
	@echo "-----------------------------------------------------"

	@echo "Executing: bundle exec mutant run $(TEMP_ACTUAL_MUTANT_ARGS) $(SUBJECTS_TO_RUN)"
	@bundle exec mutant run $(TEMP_ACTUAL_MUTANT_ARGS) $(SUBJECTS_TO_RUN)

.PHONY: install test mutate
