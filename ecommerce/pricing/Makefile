install:
	@bundle install

test:
	@bundle exec ruby -rrake/rake_test_loader test/*_test.rb

mutate:
	@RAILS_ENV=test bundle exec mutant run

.PHONY: install test mutate
