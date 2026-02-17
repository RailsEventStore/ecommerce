---
name: read-model
description: Build a new read model following project conventions (event handlers, tests, migration, configuration)
---

# Read Model Builder

## When to use

Use this skill when asked to create a new read model or add event handlers to an existing read model in any Rails application under `apps/`.

## Working Directory

Determine which app the read model belongs to. Default is `apps/rails_application/` unless the user specifies another app (e.g. `apps/crm/`, `apps/todo_mvc/`). All paths below are relative to the target app directory.

## Step-by-step process

### 1. Gather requirements

Before writing any code, clarify:
- The **module name** for the read model (e.g. `Wishlist`, `Notifications`)
- Which **domain events** it will subscribe to (e.g. `Catalog::ProductAdded`, `Ordering::OrderPlaced`)
- What **data** needs to be stored and queried
- What **facade methods** the rest of the app needs — only add facade methods that are actually used by controllers/views, not speculative ones

### 2. Write tests first (TDD)

Create a **single test file** at `test/{module_name}/{module_name}_test.rb` (relative to the app directory).

**Test file conventions:**

```ruby
# test/{module_name}/{module_name}_test.rb
require "test_helper"

module ModuleName
  class ModuleNameTest < InMemoryTestCase
    cover "ModuleName*"

    def test_record_created
      create_record(record_id)

      assert_equal(1, ModuleName.facade_method(store_id).count)
    end

    def test_record_updated
      create_record(record_id)
      create_record(other_record_id)
      update_record(record_id, "new value")

      result = ModuleName.facade_method(store_id).find_by!(uid: record_id)
      assert_equal("new value", result.attribute)
      assert_nil(ModuleName.facade_method(store_id).find_by!(uid: other_record_id).attribute)
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def record_id
      @record_id ||= SecureRandom.uuid
    end

    def other_record_id
      @other_record_id ||= SecureRandom.uuid
    end

    def store_id
      @store_id ||= SecureRandom.uuid
    end

    def create_record(rid, sid = store_id)
      event_store.publish(DomainContext::RecordCreated.new(data: { record_id: rid }))
      event_store.publish(Stores::RecordRegistered.new(data: { record_id: rid, store_id: sid }))
    end

    def update_record(rid, value)
      event_store.publish(DomainContext::RecordUpdated.new(data: { record_id: rid, value: value }))
    end
  end
end
```

**Test rules:**
- Inherit from `InMemoryTestCase`
- Use `cover "ModuleName*"` for mutation testing
- In `rails_application`, override `configure` to load only the read model's own configuration:
  ```ruby
  def configure(event_store, _command_bus)
    ModuleName::Configuration.new.call(event_store)
  end
  ```
- In other apps (e.g. `todo_mvc`), the full `Configuration` is loaded in `before_setup` — no override needed if the app only has a few read models
- Test via `event_store.publish(event)` to trigger handlers
- Assert using **facade methods**, never access ActiveRecord directly
- Use `assert_equal(expected, actual)` with parentheses always
- **Single test file** per read model — keep all handler tests together
- No comments in tests
- **Event flows must reflect the real application flow** — include `Stores::*Registered` events for store assignment, `Crm::CustomerRegistered` before customer assignment, etc.
- Use helper methods (e.g. `create_record`, `register_customer`) to express realistic event sequences
- Always test with **multiple records** to kill `find_by` → `Model.update!` mutations
- If a read model test needs `Ecommerce::Configuration` or `Processes::Configuration` to pass, that's a smell — the test is probably using `run_command` instead of publishing events directly, or the read model depends on another read model

### 3. Create the database migration

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_{table_name}.rb
class CreateTableName < ActiveRecord::Migration[8.0]
  def change
    create_table :{table_name} do |t|
      t.uuid :some_uuid_column
      t.string :name
      t.decimal :amount

      t.timestamps
    end
  end
end
```

Run `rails db:migrate` after creating.

### 4. Create the read model module

Everything goes in **one file**: `app/read_models/{module_name}/configuration.rb`. It contains:
- ActiveRecord model class(es) with `private_constant`
- Module-level facade methods (only those used by controllers/views)
- EventHandler class with all event handling logic
- Configuration class that wires event subscriptions

**Three patterns exist in the codebase:**

#### Pattern A: EventHandler with case/when (preferred for custom logic)

Use when events require different handling logic. All handlers go in a single EventHandler class using `case event`.

```ruby
# app/read_models/{module_name}/configuration.rb
module ModuleName
  class Record < ApplicationRecord
    self.table_name = "table_name"
  end

  private_constant :Record

  def self.facade_method(store_id)
    Record.where(store_id: store_id)
  end

  class EventHandler
    def call(event)
      case event
      when DomainContext::RecordCreated
        Record.create!(uid: event.data.fetch(:record_id))
      when Stores::RecordRegistered
        find_record(event).update!(store_id: event.data.fetch(:store_id))
      when DomainContext::RecordUpdated
        find_record(event).update!(attribute: event.data.fetch(:attribute))
      end
    end

    private

    def find_record(event)
      Record.find_by!(uid: event.data.fetch(:record_id))
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(EventHandler.new, to: [
        DomainContext::RecordCreated,
        Stores::RecordRegistered,
        DomainContext::RecordUpdated
      ])
    end
  end
end
```

#### Pattern B: SingleTableReadModel (event_store passed to `initialize`)

Use when the read model is a simple projection that copies event attributes to a single table.

```ruby
# app/read_models/{module_name}/configuration.rb
module ModuleName
  class Record < ApplicationRecord
    self.table_name = "table_name"
  end

  private_constant :Record

  def self.facade_method(id)
    Record.where(some_column: id)
  end

  class Configuration
    def initialize(event_store)
      @read_model = SingleTableReadModel.new(event_store, Record, :record_id)
      @event_store = event_store
    end

    def call
      @read_model.subscribe_create(DomainContext::RecordCreated)
      @read_model.subscribe_copy(DomainContext::NameSet, :name)
      @read_model.subscribe_copy(DomainContext::PriceSet, :price)
    end
  end
end
```

#### Pattern C: Separate handler classes (legacy)

Some older read models still use one class per event type in separate files. When modifying these, prefer consolidating into Pattern A.

### 5. EventHandler rules

- Always use `event.data.fetch(:key)`, never `event.data[:key]` or `event[:key]`
- **Single EventHandler class** with `case event` — no separate files per event type
- Always use `find_by!` for record lookups — records must exist because events follow the real application flow (e.g., `OfferDrafted` always comes before `OrderRegistered`)
- **Never use `find_by` with `&.` safe navigation** — this hides bugs. If a record is missing, it means the test or event flow is wrong, not that the handler should silently skip
- **No `return unless record` guards** — use `find_by!` instead
- No comments
- No named params in method calls unless required
- No local variables, prefer method calls
- Extract shared `find_*` methods as private helpers for reusability

### 6. Facade methods

- Only create facade methods that are **actually called by controllers or views**
- Do not create speculative facade methods "in case they might be useful"
- If a facade method is no longer used, remove it

### 7. Register in lib/configuration.rb

Add the read model to `lib/configuration.rb`:

**For Pattern A:**
```ruby
def enable_{module_name}_read_model(event_store)
  ModuleName::Configuration.new.call(event_store)
end
```

**For Pattern B:**
```ruby
def enable_{module_name}_read_model(event_store)
  ModuleName::Configuration.new(event_store).call
end
```

Call the method from `def call(event_store, command_bus)`.

### 8. Add to mutation testing

Add the module to the app's `.mutant.yml` under `matcher.subjects`:

```yaml
matcher:
  subjects:
    - ModuleName*
```

Add `ModuleName::Configuration#call` and `ModuleName::Rendering::*` to `matcher.ignore`.

### 9. Run verification

Run in this order:
1. `rails test test/{module_name}/` - unit tests for the new read model
2. `rails test test/integration/` - integration tests still pass
3. `make test` - all tests green
4. `RAILS_ENV=test bundle exec mutant run "ModuleName*"` - 100% mutation score

## Key conventions

- **No comments** in code or tests
- **No local variables** - prefer method calls
- **No named params** unless required
- **No `return unless` guards** — always use `find_by!`, never `find_by` with `&.`
- **Read models must not access other read models**
- **Use `private_constant`** for ActiveRecord classes
- **Facade methods only when used** by controllers/views
- **Use uuid type** in migrations for UUID columns
- **Single EventHandler class** per read model with `case event` routing — all in configuration.rb
- **Single test file** per read model
- **Test event flows must reflect real application flows** — include store registration events, customer registration, etc.
- **All calls are synchronous** - no async/concurrency concerns
- **100% mutation score required**
- **Test-first TDD** - write tests before implementation
