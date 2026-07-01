---
name: new-app
description: Scaffold a new Rails app with event sourcing, following project conventions (todomvc as reference)
---

# New App Scaffold

## When to use

Use this skill when asked to create a new Rails application in the `apps/` directory. Each app is a standalone Rails application that uses domain modules from `domains/` and the shared `infra` gem.

## Reference

`apps/todo_mvc` is the canonical reference for **app structure** (initializer, Configuration, test harness, Makefile). For the **current RES 3.0 wiring and gem versions**, use `apps/rails_application` and `apps/twitter` — todo_mvc still pins RES 2.x, which is stale. When the two disagree, follow rails_application.

## Version policy (do this first, every time)

Always scaffold on the **newest Ruby and newest Rails** — do not hardcode versions from this doc, they go stale.

- **Newest Rails**: `gem list rails --remote --exact | head -1` (checks RubyGems, not just what's installed locally). As of this writing: Rails 8.1.3.
- **Newest Ruby**: pick the highest installed under `~/.rbenv/versions/` (`ls ~/.rbenv/versions | sort -V | tail`). As of this writing: Ruby 4.0.1. Set it in the app's `.ruby-version`. Ruby 4.0.1 works with Rails 8.1 + RES 3.0 + the infra/domain gems.
- Confirm the chosen Ruby's gemset actually has the target Rails: `~/.rbenv/versions/{ruby}/bin/rails -v`.

Invoke rails/bundle via the **full rbenv path** for the chosen Ruby, e.g. `~/.rbenv/versions/4.0.1/bin/rails`, `~/.rbenv/versions/4.0.1/bin/bundle` — the `rails` shell alias may resolve to a different Ruby.

## Commit cadence

Commit frequently at natural checkpoints, not once at the end. **Commit directly on the current branch — do not create a feature branch.** Suggested commits: (1) after generating the app + configuring the Gemfile, (2) after RES wiring is green, (3) after each domain/read model. Per project convention, use the `/commit` skill and never mention Claude in commit messages.

## Step-by-step process

### 1. Gather requirements

Before writing any code, clarify:
- The **app name** (snake_case, e.g. `crm`, `inventory_tracker`)
- Which **domain modules** it will use (existing ones from `domains/` or new ones to be created)
- What the app **does** at a high level — what entities, what user actions

### 2. Generate the Rails app

Run from the `apps/` directory, using the full rbenv path for the newest Ruby (see Version policy above):

```bash
cd apps && ~/.rbenv/versions/{ruby}/bin/rails new {app_name} --database=postgresql --css=tailwind --skip-test
```

`--skip-test` (not `--skip-test-unit`, which no longer exists) drops the default test setup so we can install our own minitest + mutant harness.

**Important post-generation steps:**
- Set the app's Ruby: `echo "{ruby}" > apps/{app_name}/.ruby-version` (the generator pins the global default, which may not be the newest).
- `rails new` creates a nested `.git` directory inside the new app. **It must be removed** so the app is part of the parent repo. `rm -rf` is blocked by the repo's git-safety hook, so **ask the user to run it manually**: `rm -rf apps/{app_name}/.git`. Do not proceed to committing until it's gone.

### 3. Configure Gemfile

Add these gems to the generated Gemfile (after `jbuilder`, before the tzinfo/solid gems). Use RES 3.0 to match `rails_application`:

```ruby
gem "rails_event_store", ">= 3.0", "< 4.0"
gem "arkency-command_bus"
gem "infra", path: "../../infra"
```

Rails 8.1 with `--skip-test` does **not** generate a capybara/selenium test group. Just **add** a test group:

```ruby
group :test do
  gem "mutant-minitest"
end
```

Run `bundle install` (via the full rbenv path). Commit the generated app + Gemfile now (checkpoint 1).

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

Create `lib/configuration.rb`. For the **initial scaffold there is no domain yet**, so `call` only wires event linking — this keeps the app bootable and tests green before any domain exists:

```ruby
require_relative "../../../infra/lib/infra"

class Configuration
  def call(event_store, command_bus)
    enable_res_infra_event_linking(event_store)
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

As domains and read models are added later, extend `call`: `require_relative` the domain, add `{DomainModule}::Configuration.new.call(event_store, command_bus)`, and give each read model its own `enable_*` private method called from `call`. Do not add a `require_relative` to a domain that doesn't exist yet — it will break boot.

### 6. Create event store migration

In **RES 3.0 the generator was renamed** — the old `rails_event_store_active_record:migration` no longer exists. Use the `ruby_event_store` namespace with a data type (`jsonb` pairs cleanly with infra's `RailsEventStore::JSONClient`):

```bash
cd apps/{app_name} && ~/.rbenv/versions/{ruby}/bin/bundle exec rails generate ruby_event_store:active_record:migration --data-type=jsonb
```

Then `rails db:create && rails db:migrate` (via the full rbenv path). The generated migration creates `event_store_events` and `event_store_events_in_streams` with uuid `event_id` and `jsonb` `data`/`metadata`.

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

**Replace** the generated `test/test_helper.rb` (which has `parallelize` and `fixtures :all`):

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

Create `.mutant.yml` in the app root. On the initial scaffold there are **no subjects yet**, so start with empty lists (mutant isn't run until there's domain code to cover):

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
  subjects: []
  ignore: []
```

As each read model is added, append its namespace to `subjects` (e.g. `- Tweets*`) and its AR model + `Configuration#call` to `ignore`. See `apps/crm/.mutant.yml` for a fully-populated example.

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
	@RAILS_ENV=test bundle exec mutant run

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

## Gotchas

- **Versions go stale**: Do not hardcode Ruby/Rails versions — resolve the newest each time (see Version policy). This doc's concrete numbers (Ruby 4.0.1, Rails 8.1.3) are examples, not pins.
- **`rails`/`bundle` alias**: The shell alias may resolve to the wrong Ruby. Always use the full rbenv path: `~/.rbenv/versions/{ruby}/bin/rails`, `~/.rbenv/versions/{ruby}/bin/bundle`.
- **Nested `.git`**: `rails new` creates its own git repo. It must be removed before the app can be committed to the parent repo. `rm -rf` is **blocked by the git-safety hook** — ask the user to run `rm -rf apps/{app_name}/.git` manually.
- **`.ruby-version`**: The generator pins the rbenv global default, not necessarily the newest — overwrite it with the chosen Ruby.
- **RES 3.0 migration generator renamed**: use `ruby_event_store:active_record:migration`, not the old `rails_event_store_active_record:migration` (see step 6).
- **`bin/rails` commands** (migrations, generators, tests): Must run from `apps/{app_name}/` directory, not project root.
- **Generated boilerplate**: Rails generates channels, kamal/solid config etc. These are harmless but unused — leave them or ask user to clean up.

## Key conventions

- Each app is a standalone Rails app in `apps/`
- Apps reference domains via `require_relative "../../../domains/{name}/lib/{name}"`
- Apps reference infra via `gem "infra", path: "../../infra"`
- Read models live in `app/read_models/{name}/configuration.rb`
- All event access uses `event.data.fetch(:key)`
- Controllers use `command_bus.call(...)` for writes, read models for queries
- UUIDs for all business entity IDs (`SecureRandom.uuid`)
- Test-first TDD, 100% mutation score
