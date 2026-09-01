install:
	@bin/setup

dev:
	@make -j 2 web css

architecture:
	@cd ../.. && BUNDLE_GEMFILE=apps/insurance/Gemfile bundle exec archspec check

test: architecture
	@bin/rails test

mutate: tailwind
	@RAILS_ENV=test bundle exec mutant run

tailwind:
	@bin/rails tailwindcss:build

css:
	@bin/rails tailwindcss:watch

web:
	@bin/rails server -p 3003

.PHONY: install dev architecture test mutate tailwind css web
