---
name: domain
description: Create a new domain bounded context with aggregates, commands, events, and handlers
---

# Domain Builder

## When to use

Use this skill when asked to create a new domain module (bounded context) in the `domains/` directory, or to add new aggregates/commands/events to an existing domain.

## Reference

Two patterns exist in the codebase:
- **Simple** (todo): Everything in a single file `lib/{domain}/todo.rb`
- **Structured** (crm, ordering, etc.): Separate files for commands, events, aggregates, and handlers

Use the **structured** pattern for any non-trivial domain. The simple pattern is only for demos.

## Step-by-step process

### 1. Gather requirements

Before writing any code, clarify:
- The **domain name** (snake_case, e.g. `project_management`, `ticketing`)
- The **aggregates** — what are the core entities? (e.g. `Customer`, `Deal`, `Contact`)
- For each aggregate: what **commands** can be issued and what **events** do they produce?
- What **business rules** does the aggregate enforce? (invariants, state guards)

### 2. Scaffold the domain directory

Create the directory structure:

```
domains/{domain_name}/
├── Gemfile
├── Makefile
├── .mutant.yml
├── lib/
│   ├── {domain_name}.rb              # Module entry point + Configuration
│   └── {domain_name}/
│       ├── commands/
│       │   └── {command_name}.rb      # One file per command
│       ├── events/
│       │   └── {event_name}.rb        # One file per event
│       ├── {aggregate_name}.rb        # Aggregate root
│       └── {aggregate_name}_service.rb # Command handlers
└── test/
    ├── test_helper.rb
    └── {test_name}_test.rb            # One file per test concern
```

### 3. Create boilerplate files

**Gemfile:**

```ruby
source "https://rubygems.org"

eval_gemfile "../../infra/Gemfile.test"
gem "infra", path: "../../infra"
```

**Makefile:**

```makefile
install:
	@bundle install

test:
	@bundle exec ruby -e "require \"rake/rake_test_loader\"" test/*_test.rb

mutate:
	@RAILS_ENV=test bundle exec mutant run

.PHONY: install test mutate
```

**.mutant.yml:**

```yaml
requires:
  - ./test/test_helper
integration: minitest
usage: opensource
coverage_criteria:
  process_abort: true
matcher:
  subjects:
    - {DomainModule}*
  ignore:
    - {DomainModule}::Configuration#call
```

### 4. Write tests first (TDD)

Create `test/test_helper.rb`:

```ruby
require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/{domain_name}"

module DomainModule
  class Test < Infra::InMemoryTest
    def before_setup
      super
      Configuration.new.call(event_store, command_bus)
    end

    private

    def some_helper(id, attribute)
      run_command(SomeCommand.new(entity_id: id, attribute: attribute))
    end
  end
end
```

Create test files — one per logical concern (e.g. `test/registration_test.rb`, `test/assignment_test.rb`):

```ruby
require_relative "test_helper"

module DomainModule
  class SomeTest < Test
    cover "DomainModule*"

    def test_entity_can_be_created
      id = SecureRandom.uuid
      create_entity(id, "some value")

      expected_event = EntityCreated.new(data: { entity_id: id, attribute: "some value" })
      assert_events("DomainModule::Entity$#{id}", expected_event) do
        create_entity(id, "some value")
      end
    end

    def test_cannot_create_same_entity_twice
      id = SecureRandom.uuid
      create_entity(id, "value")

      assert_raises(Entity::AlreadyExists) do
        create_entity(id, "value")
      end
    end

    private

    def create_entity(id, value)
      run_command(CreateEntity.new(entity_id: id, attribute: value))
    end
  end
end
```

**Test conventions:**
- Use `cover "DomainModule*"` for mutation testing
- Use `run_command(...)` to dispatch commands (provided by `Infra::InMemoryTest`)
- Use `assert_events(stream, expected_event) { block }` to verify events
- Use `assert_raises(ErrorClass) { block }` for invariant violations
- Extract command-calling helpers as private methods
- Test both happy paths and invariant violations (double-creation, invalid state transitions)

### 5. Create commands

One file per command in `lib/{domain_name}/commands/`:

```ruby
module DomainModule
  class CreateEntity < Infra::Command
    attribute :entity_id, Infra::Types::UUID
    attribute :name, Infra::Types::String
    alias aggregate_id entity_id
  end
end
```

**Command conventions:**
- Inherit from `Infra::Command`
- Use `Infra::Types::UUID` for UUIDs, `Infra::Types::String` for strings
- Add `alias aggregate_id {entity_id_field}` so the handler can use `command.aggregate_id`

### 6. Create events

One file per event in `lib/{domain_name}/events/`:

```ruby
module DomainModule
  class EntityCreated < Infra::Event
    attribute :entity_id, Infra::Types::UUID
    attribute :name, Infra::Types::String
  end
end
```

**Event conventions:**
- Inherit from `Infra::Event`
- Events are named in past tense (`Created`, `Updated`, `Assigned`, `Promoted`)
- Include the aggregate ID and any relevant data

### 7. Create aggregate root

```ruby
module DomainModule
  class Entity
    include AggregateRoot

    AlreadyExists = Class.new(StandardError)
    NotFound = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

    def create(name)
      raise AlreadyExists if @created
      apply EntityCreated.new(data: { entity_id: @id, name: name })
    end

    def update_name(name)
      raise NotFound unless @created
      apply EntityNameUpdated.new(data: { entity_id: @id, name: name })
    end

    private

    on EntityCreated do |event|
      @created = true
    end

    on EntityNameUpdated do |event|
    end
  end
end
```

**Aggregate conventions:**
- `include AggregateRoot`
- State tracked via instance variables (`@created`, `@completed`, etc.)
- Business rules enforced via `raise` before `apply`
- `on EventClass do |event|` blocks update internal state
- Events that don't change state still need empty `on` blocks
- Custom error classes as `Class.new(StandardError)`

### 8. Create command handlers

One handler class per command, grouped in a service file:

```ruby
module DomainModule
  class OnCreateEntity
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Entity, command.aggregate_id) do |entity|
        entity.create(command.name)
      end
    end
  end

  class OnUpdateEntityName
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Entity, command.aggregate_id) do |entity|
        entity.update_name(command.name)
      end
    end
  end
end
```

**Handler conventions:**
- Each handler wraps `@repository.with_aggregate(AggregateClass, id) { |agg| ... }`
- Handler names describe the action: `OnRegistration`, `OnSetCustomer`, `OnPromoteCustomerToVip`
- All in one `_service.rb` file per aggregate, or separate files for clarity

### 9. Create module entry point with Configuration

Create `lib/{domain_name}.rb`:

```ruby
require "infra"
require_relative "{domain_name}/commands/create_entity"
require_relative "{domain_name}/commands/update_entity_name"
require_relative "{domain_name}/events/entity_created"
require_relative "{domain_name}/events/entity_name_updated"
require_relative "{domain_name}/entity_service"
require_relative "{domain_name}/entity"

module DomainModule
  class Configuration
    def call(event_store, command_bus)
      command_bus.register(CreateEntity, OnCreateEntity.new(event_store))
      command_bus.register(UpdateEntityName, OnUpdateEntityName.new(event_store))
    end
  end
end
```

**Configuration conventions:**
- `require "infra"` first, then all domain files
- Each command registered with its handler
- Handlers receive `event_store` in constructor

### 10. Run verification

```bash
cd domains/{domain_name}
bundle install
make test          # All tests pass
make mutate        # 100% mutation score
```

Then from the project root:

```bash
make test          # Ensure nothing is broken globally
```

## Key conventions

- Commands are imperative: `RegisterCustomer`, `AddTodo`, `AssignDeal`
- Events are past tense: `CustomerRegistered`, `TodoAdded`, `DealAssigned`
- Aggregates enforce business rules (invariants) before applying events
- UUIDs for all entity IDs
- `Infra::Types::UUID` and `Infra::Types::String` for typed attributes
- Test-first TDD, 100% mutation score
- Each domain is fully independent — no cross-domain imports
- Domains only communicate via events (consumed by read models and process managers in apps)
