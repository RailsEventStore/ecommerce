install:
	@bundle install

test:
	@bundle exec ruby -e "require \"rake/rake_test_loader\"" test/*_test.rb

mutate:
	@RAILS_ENV=test bundle exec mutant run

.PHONY: install test mutate
