install:
	@bin/setup

dev:
	@make -j 2 web css

test:
	@bin/rails test

mutate:
	@bundle exec mutant run

tailwind:
	@bin/rails tailwindcss:build

css:
	@bin/rails tailwindcss:watch

web:
	@bin/rails server -p 3001

.PHONY: install dev test mutate tailwind css web
