---
name: new-app
description: Scaffold a new Rails app with event sourcing, following project conventions (todomvc as reference)
---

# New App Scaffold

## When to use

Use this skill when asked to create a new Rails application in the `apps/` directory. Each app is a standalone Rails application that uses domain modules from `domains/` and the shared `infra` gem.

## Reference

The `apps/todo_mvc` app is the canonical reference. All patterns below are extracted from it.

## Step-by-step process

### 1. Gather requirements

Before writing any code, clarify:
- The **app name** (snake_case, e.g. `crm`, `inventory_tracker`)
- Which **domain modules** it will use (existing ones from `domains/` or new ones to be created)
- What the app **does** at a high level — what entities, what user actions

### 2. Generate the Rails app

Run from the project root:

```bash
cd apps && rails new {app_name} --database=postgresql --css=tailwind --skip-test-unit
```

Then clean up unnecessary files and add the project-specific setup.

### 3. Configure Gemfile

Add these gems to the generated Gemfile:

```ruby
gem "rails_event_store", ">= 2.15.0", "< 3.0"
gem "arkency-command_bus"
gem "infra", path: "../../infra"
```

Add to test group:

```ruby
group :test do
  gem "mutant-minitest"
end
```

Run `bundle install`.

### 4. Create event store initializer

Create `config/initializers/rails_event_store.rb`:

```ruby
require "rails_event_store"
require "arkency/command_bus"

require_relative "../../lib/configuration"

Rails.configuration.to_prepare do
  Rails.configuration.event_store = Infra::EventStore.main
  Rails.configuration.command_bus = Arkency::CommandBus.new

  Configuration.new.call(Rails.configuration.event_store, Rails.configuration.command_bus)
end
```

### 5. Create app-level Configuration

Create `lib/configuration.rb`:

```ruby
require_relative "../../../domains/{domain_name}/lib/{domain_name}"
require_relative "../../../infra/lib/infra"

class Configuration
  def call(event_store, command_bus)
    enable_res_infra_event_linking(event_store)
    # enable_{read_model_name}_read_model(event_store) — add as read models are created

    {DomainModule}::Configuration.new.call(event_store, command_bus)
  end

  private

  def enable_res_infra_event_linking(event_store)
    [
      RailsEventStore::LinkByEventType.new,
      RailsEventStore::LinkByCorrelationId.new,
      RailsEventStore::LinkByCausationId.new
    ].each { |h| event_store.subscribe_to_all_events(h) }
  end
end
```

Each read model gets its own `enable_*` private method, called from `call`.

### 6. Create event store migration

Generate the RES migration:

```bash
cd apps/{app_name} && rails generate rails_event_store_active_record:migration
```

Run `rails db:create && rails db:migrate`.

### 7. Create ApplicationController

Ensure `app/controllers/application_controller.rb` has:

```ruby
class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  def command_bus
    Rails.configuration.command_bus
  end

  def event_store
    Rails.configuration.event_store
  end
end
```

### 8. Create test helper

Create `test/test_helper.rb`:

```ruby
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mutant/minitest/coverage"

ActiveJob::Base.logger = Logger.new(nil)

class InMemoryRESTestCase < ActiveSupport::TestCase
  def before_setup
    result = super
    @previous_event_store = Rails.configuration.event_store
    @previous_command_bus = Rails.configuration.command_bus
    Rails.configuration.event_store = Infra::EventStore.in_memory
    Rails.configuration.command_bus = Arkency::CommandBus.new

    Configuration.new.call(
      Rails.configuration.event_store, Rails.configuration.command_bus
    )
    result
  end

  def before_teardown
    result = super
    Rails.configuration.event_store = @previous_event_store
    Rails.configuration.command_bus = @previous_command_bus
    result
  end

  def event_store
    Rails.configuration.event_store
  end

  def command_bus
    Rails.configuration.command_bus
  end
end

class InMemoryRESIntegrationTestCase < ActionDispatch::IntegrationTest
  def before_setup
    result = super
    @previous_event_store = Rails.configuration.event_store
    @previous_command_bus = Rails.configuration.command_bus
    Rails.configuration.event_store = Infra::EventStore.in_memory_rails
    Rails.configuration.command_bus = Arkency::CommandBus.new

    Configuration.new.call(Rails.configuration.event_store, Rails.configuration.command_bus)
    result
  end

  def before_teardown
    result = super
    Rails.configuration.event_store = @previous_event_store
    Rails.configuration.command_bus = @previous_command_bus
    result
  end

  def command_bus
    Rails.configuration.command_bus
  end
end
```

### 9. Create .mutant.yml

Create `.mutant.yml` in the app root:

```yaml
includes:
  - test
requires:
  - ./config/environment
integration: minitest
usage: opensource
coverage_criteria:
  timeout: true
  process_abort: true
matcher:
  subjects:
    - ReadModelName*
  ignore:
    - ReadModelName::ModelClass
    - ReadModelName::Configuration#call
```

Add each read model's namespace to `subjects` and its AR model + Configuration#call to `ignore`.

### 10. Register in root Makefile

Add targets to the root `Makefile`:

```makefile
install-{app_name}:
	@make -C apps/{app_name} install

test-{app_name}:
	@make -C apps/{app_name} test

mutate-{app_name}:
	@make -C apps/{app_name} mutate
```

Add `install-{app_name}` to the `install:` target, `test-{app_name}` to `test:`, and `mutate-{app_name}` to `mutate:`.

### 11. Create app Makefile

Create `Makefile` in the app directory:

```makefile
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
	@bin/rails server -p {port}

.PHONY: install dev test mutate tailwind css web
```

Use a unique port per app (3000 for rails_application, 3001+ for new apps).

## Controller pattern

Controllers dispatch commands and query read models:

```ruby
class ResourceController < ApplicationController
  def index
    @records = ReadModelName.all
  end

  def create
    id = SecureRandom.uuid
    ActiveRecord::Base.transaction do
      command_bus.call(DomainModule::CreateCommand.new(id: id, ...))
    end
    redirect_to root_path
  end

  def update
    command_bus.call(DomainModule::UpdateCommand.new(id: params[:id], ...))
    redirect_to root_path
  end

  def destroy
    command_bus.call(DomainModule::DeleteCommand.new(id: params[:id]))
    redirect_to root_path
  end
end
```

## Build order

Build the app incrementally, with tests passing at each step:

1. Scaffold Rails app + boilerplate (steps 2-11)
2. Create or reference domain modules (use the `/domain` skill)
3. Add read models one at a time (use the `/read-model` skill)
4. Add controllers + views for each read model
5. Add integration tests
6. Run `make test` and mutation testing

## Key conventions

- Each app is a standalone Rails app in `apps/`
- Apps reference domains via `require_relative "../../../domains/{name}/lib/{name}"`
- Apps reference infra via `gem "infra", path: "../../infra"`
- Read models live in `app/read_models/{name}/configuration.rb`
- All event access uses `event.data.fetch(:key)`
- Controllers use `command_bus.call(...)` for writes, read models for queries
- UUIDs for all business entity IDs (`SecureRandom.uuid`)
- Test-first TDD, 100% mutation score
