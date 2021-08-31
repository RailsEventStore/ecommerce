BUNDLE_GEMFILE=../../rails_application/Gemfile

install:
	@env BUNDLE_GEMFILE=$(BUNDLE_GEMFILE) bundle install

test:
	@env BUNDLE_GEMFILE=$(BUNDLE_GEMFILE) bundle exec ruby -rrake/rake_test_loader test/*_test.rb

.PHONY: install test
