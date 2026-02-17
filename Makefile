CONTEXTS = $(shell find domains -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)

$(addprefix install-, $(CONTEXTS)):
	@make -C domains/$(subst install-,,$@) install

$(addprefix test-, $(CONTEXTS)):
	@make -C domains/$(subst test-,,$@) test

$(addprefix mutate-, $(CONTEXTS)):
	@make -C domains/$(subst mutate-,,$@) mutate

install-rails:
	@make -C apps/rails_application install

test-rails:
	@make -C apps/rails_application test

mutate-rails:
	@make -C apps/rails_application mutate

install-crm:
	@make -C apps/crm install

test-crm:
	@make -C apps/crm test

mutate-crm:
	@make -C apps/crm mutate

install-infra:
	@make -C infra install

test-infra:
	@make -C infra test

mutate-infra:
	@make -C infra mutate

dev:
	@make -C apps/rails_application dev

install: install-infra install-rails install-crm $(addprefix install-, $(CONTEXTS)) ## Install all dependencies

test: test-infra test-rails test-crm $(addprefix test-, $(CONTEXTS)) ## Run all unit tests

mutate: mutate-infra mutate-rails mutate-crm $(addprefix mutate-, $(CONTEXTS)) ## Run all mutation coverage

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
