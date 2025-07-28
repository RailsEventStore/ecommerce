install:
	@bundle install

test:
	@bundle exec ruby -e "require \"rake/rake_test_loader\"" test/*_test.rb

mutate:
ifeq ($(CI_MUTATE_SUBJECTS),)
	@echo "Running all mutation tests (local or full CI run)"
	@env RAILS_ENV=test bundle exec mutant run
else
	@echo "Running CI mutation tests for subjects: $(CI_MUTATE_SUBJECTS)"
	@env RAILS_ENV=test bundle exec mutant run $(CI_MUTATE_SUBJECTS)
endif

.PHONY: install test mutate
