CONTEXTS = $(shell find ecommerce -type d -maxdepth 1 -mindepth 1 -exec basename {} \;)

$(addprefix install-, $(CONTEXTS)):
	@make -C ecommerce/$(subst install-,,$@) install

install: $(addprefix install-, $(CONTEXTS)) ## Install all dependencies

$(addprefix test-, $(CONTEXTS)):
	@make -C ecommerce/$(subst test-,,$@) test

test: $(addprefix test-, $(CONTEXTS)) ## Run all unit tests

$(addprefix mutate-, $(CONTEXTS)):
	@make -C ecommerce/$(subst mutate-,,$@) mutate

mutate: $(addprefix mutate-, $(CONTEXTS)) ## Run all mutation coverage

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
