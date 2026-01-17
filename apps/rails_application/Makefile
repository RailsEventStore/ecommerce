GIT_BASE_SHA ?= $(shell git merge-base HEAD origin/master)

install: ## Installs dependencies, runs migrations, creates db & seeds if necessary
	@bin/setup

dev:
	@$(MAKE) -j 2 web css

build-tailwind:
	@echo "Building Tailwind CSS..."
	@bin/rails tailwindcss:build

mutate: build-tailwind
	@echo "Running full mutation tests..."
	@bundle exec mutant run

mutate-changes: ## Run incremental mutation tests on changes
	@echo "Running incremental mutation tests against $(GIT_BASE_SHA)..."
	@RAILS_ENV=test bundle exec mutant run --since $(GIT_BASE_SHA)

mutate-processes: ## Run mutation tests for Processes namespace
	@echo "Running mutation tests for Processes..."
	@RAILS_ENV=test bundle exec mutant run "Processes*"

mutate-orders: ## Run mutation tests for Orders namespace
	@echo "Running mutation tests for Orders..."
	@RAILS_ENV=test bundle exec mutant run "Orders*"

mutate-order-header: ## Run mutation tests for OrderHeader namespace
	@echo "Running mutation tests for OrderHeader..."
	@RAILS_ENV=test bundle exec mutant run "OrderHeader*"

mutate-client-orders: ## Run mutation tests for ClientOrders namespace
	@echo "Running mutation tests for ClientOrders..."
	@RAILS_ENV=test bundle exec mutant run "ClientOrders*"

mutate-invoices: ## Run mutation tests for Invoices namespace
	@echo "Running mutation tests for Invoices..."
	@RAILS_ENV=test bundle exec mutant run "Invoices*"

mutate-shipments: ## Run mutation tests for Shipments namespace
	@echo "Running mutation tests for Shipments..."
	@RAILS_ENV=test bundle exec mutant run "Shipments*"

mutate-vat-rates: ## Run mutation tests for VatRates namespace
	@echo "Running mutation tests for VatRates..."
	@RAILS_ENV=test bundle exec mutant run "VatRates*"

mutate-coupons: ## Run mutation tests for Coupons namespace
	@echo "Running mutation tests for Coupons..."
	@RAILS_ENV=test bundle exec mutant run "Coupons*"

mutate-products: ## Run mutation tests for Products namespace
	@echo "Running mutation tests for Products..."
	@RAILS_ENV=test bundle exec mutant run "Products*"

mutate-public-offer: ## Run mutation tests for PublicOffer namespace
	@echo "Running mutation tests for PublicOffer..."
	@RAILS_ENV=test bundle exec mutant run "PublicOffer*"

mutate-customers: ## Run mutation tests for Customers namespace
	@echo "Running mutation tests for Customers..."
	@RAILS_ENV=test bundle exec mutant run "Customers*"

mutate-admin: ## Run mutation tests for Admin namespace
	@echo "Running mutation tests for Admin..."
	@RAILS_ENV=test bundle exec mutant run "Admin*"

mutate-time-promotions: ## Run mutation tests for TimePromotions namespace
	@echo "Running mutation tests for TimePromotions..."
	@RAILS_ENV=test bundle exec mutant run "TimePromotions*"

mutate-returns: ## Run mutation tests for Returns namespace
	@echo "Running mutation tests for Returns..."
	@RAILS_ENV=test bundle exec mutant run "Returns*"

mutate-availability: ## Run mutation tests for Availability namespace
	@echo "Running mutation tests for Availability..."
	@RAILS_ENV=test bundle exec mutant run "Availability*"

mutate-client-inbox: ## Run mutation tests for ClientInbox namespace
	@echo "Running mutation tests for ClientInbox..."
	@RAILS_ENV=test bundle exec mutant run "ClientInbox*"

mutate-authorization: ## Run mutation tests for Authorization namespace
	@echo "Running mutation tests for Authorization..."
	@RAILS_ENV=test bundle exec mutant run "Authorization*"

mutate-client-authentication: ## Run mutation tests for ClientAuthentication namespace
	@echo "Running mutation tests for ClientAuthentication..."
	@RAILS_ENV=test bundle exec mutant run "ClientAuthentication*"

test: build-tailwind
	@echo "Running unit tests..."
	@BROWSERSLIST_IGNORE_OLD_DATA=1 bin/rails test

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%%-30s\033[0m %%s\n", $$1, $$2}'

css:
	@bin/rails tailwindcss:watch[always]

web:
	@bin/rails server -p 3000

test-mutant-runner: build-tailwind
	@RAILS_ENV=test bundle exec mutant test -j 4

.PHONY: help install dev build-tailwind test mutate mutate-changes mutate-processes mutate-orders mutate-order-header mutate-client-orders mutate-invoices mutate-shipments mutate-vat-rates mutate-coupons mutate-products mutate-public-offer mutate-customers mutate-admin mutate-time-promotions mutate-returns mutate-availability mutate-client-inbox mutate-authorization mutate-client-authentication css web test-mutant-runner
.DEFAULT_GOAL := help
