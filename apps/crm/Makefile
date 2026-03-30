install:
	@bin/setup

dev:
	@make -j 2 web css

test:
	@bin/rails test

mutate:
	@RAILS_ENV=test bundle exec mutant run "Companies*"
	@RAILS_ENV=test bundle exec mutant run "Contacts*"
	@RAILS_ENV=test bundle exec mutant run "Pipelines*"
	@RAILS_ENV=test bundle exec mutant run "Deals*"
	@RAILS_ENV=test bundle exec mutant run "Activities*"

tailwind:
	@bin/rails tailwindcss:build

css:
	@bin/rails tailwindcss:watch

web:
	@bin/rails server -p 3001

.PHONY: install dev test mutate tailwind css web
