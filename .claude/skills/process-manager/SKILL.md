---
name: process-manager
description: Creates and changes application-level process managers with event-to-command tests, state reconstruction, subscriptions, and mutation coverage. Use for workflow coordination in apps/.
---

# Process Manager Builder

## When to use

Use this skill when creating, changing, or refactoring a process that reacts to events and coordinates domain commands. Use `/domain` for the commands, events, and aggregate rules themselves; use `/read-model` for projections queried by the UI.

## Working directory and references

Determine the target application first; default to `apps/rails_application/`. Keep processes in the application, not in a shared domain. Match the target app's namespace, configuration, and test helpers rather than assuming every app uses `Processes`.

For the main Rails app, paths below are relative to `apps/rails_application/`:

- Process: `app/processes/processes/{process_name}.rb`
- Tests: `test/processes/{process_name}_test.rb`
- Subscriptions: `app/processes/processes/configuration.rb`
- Application wiring: `lib/configuration.rb`
- Test helpers: `ProcessTest` in `test/test_helper.rb`

Read the closest existing process and its tests before writing code:

- `Processes::ConfirmOrderOnPaymentCaptured` for a stateless event-to-command reaction.
- `Processes::OrderAcceptance` and `test/processes/order_acceptance_test.rb` for state reconstruction and request-triggered commands.
- `Processes::ShipmentProcess` and its tests for prerequisites arriving in different valid orders and completion events.
- `Processes::ReservationProcess` and its tests for synchronous command failures and compensation.

Stateful processes use `RubyEventStore::ProcessManager.with_state`. Check the target app's `Gemfile.lock` and the installed gem source before relying on its API; do not introduce a new process-manager abstraction.

## Step-by-step process

### 1. Define the process contract and tests

Identify:

- The business process and the application that owns it.
- Input events, their producers, and the correlation ID shared by those events.
- Commands to issue, their arguments, and the events or prerequisites that trigger them.
- Events that record completion, cancellation, or failure, and any required compensating commands.
- Cases that must issue no commands, including incomplete prerequisites and already-completed work.

Keep aggregate invariants in the domain. Coordinate domains through events and the command bus, not by loading other aggregates or querying UI read models for process state. All calls here are synchronous; do not add jobs, queues, locks, or retry infrastructure for hypothetical concurrency.

Propose the event sequences and expected commands before implementation. For changes to an existing process, first run `bin/rails test test/integration/` to establish the baseline. Then work test-first on the process contract.

### 2. Write process tests first

Extend the existing test file when changing a process. In the main Rails app, inherit from `ProcessTest` and use `cover "Processes::YourProcess*"` with the actual class name, including its state class.

Use `given(events, process:)`: it appends events before calling the process, so the event IDs exist when the process manager links them. `given(events)` alone only appends events; it does not run the process or build its history. Do not wire the full application into a process unit test; the supplied fake command bus records commands without executing domain handlers.

Example using the existing order-acceptance contract:

```ruby
require "test_helper"

module Processes
  class OrderAcceptanceTest < ProcessTest
    cover "Processes::OrderAcceptance*"

    def test_accepts_only_when_requested
      given([item_added], process:)
      assert_no_command

      given([acceptance_requested], process:)

      assert_equal(1, command_bus.all_received.size)
      assert_instance_of(Pricing::AcceptOffer, command_bus.received)
      assert_equal(order_id, command_bus.received.order_id)
    end

    private

    def process
      OrderAcceptance.new.with(event_store: event_store, command_bus: command_bus)
    end

    def item_added
      Pricing::PriceItemAdded.new(
        data: { order_id: order_id, product_id: SecureRandom.uuid, price: 20 }
      )
    end

    def acceptance_requested
      Pricing::OrderAcceptanceRequested.new(data: { order_id: order_id })
    end
  end
end
```

Test observable outputs, not private state or calls to `apply`, `act`, `read`, or `link`:

- Assert command count, type, and meaningful arguments. A last-command assertion alone misses extra commands. Use `assert_all_commands` when command equality supports it; otherwise assert types and attributes as above.
- Test each missing prerequisite and each business boundary, not just the happy path. For order acceptance, distinguish an empty order, a nonempty order, and an order emptied by removals.
- Exercise both event orders only when both are valid application flows, as in shipment address and order registration.
- Interleave events for two different correlation IDs with different histories; assert that their commands do not mix.
- Recreate the process with the same event store between steps to prove it reconstructs state rather than retaining incidental instance state.
- Feed completion events explicitly: the fake bus does not publish them. Clear recorded commands with `command_bus.clear_all_received` before asserting that a later event issues no new commands.
- Where relevant, test cancellation, later requests, synchronous domain rejection, and compensation using the existing reservation tests as a reference. Do not invent duplicate-delivery guarantees the process-manager gem does not provide.

Run the focused test and observe the expected failure before implementing the behavior.

### 3. Choose the simplest implementation

#### Stateless reaction

If one event contains everything needed, use a plain subscriber with `initialize(command_bus)` and `call(event)`, following `ConfirmOrderOnPaymentCaptured`. A direct positional mapping can use the existing `Infra::Process` helper, as in the coupon-discount subscription. Do not introduce persisted state for a simple mapping.

#### Stateful coordination

Follow `OrderAcceptance` for the complete implementation. The class includes:

```ruby
include RubyEventStore::ProcessManager.with_state { ProcessState }

subscribes_to(
  Pricing::PriceItemAdded,
  Pricing::PriceItemRemoved,
  Pricing::OrderAcceptanceRequested
)
```

Implement the following methods and state inside the process class:

- `fetch_id(event)` returns the correlation ID using `event.data.fetch(:order_id)` or the relevant key. Different event types may use different keys for the same process ID; see `apps/twitter/app/processes/timeline_delivery_process.rb` from the repository root.
- `ProcessState` is a `Data.define(...)` value with defaults so `ProcessState.new` works without arguments. Use `state.with(...)` for transitions; avoid mutating nested arrays or hashes and follow the existing collection-freezing patterns where needed.
- `apply(event)` returns the next state for every subscribed event. Keep it free of commands, event publication, and other effects: it runs again when history is replayed.
- `act` issues commands based on reconstructed state, using the supplied `command_bus` and `id`. Put readiness predicates on the state when that makes the decision clearer.

The gem reads the process stream, links the current event, rebuilds state, and calls `act`. Do not duplicate that machinery or add a separate state table. Keep transient action flags tied to the triggering event and clear them on later non-triggering events, as `OrderAcceptance` does. Observe completion events when they determine whether another command is needed, as `ShipmentProcess` does.

Some existing processes publish derived events rather than commands, such as `TotalOrderValue`. If that is the required contract, keep publication in `act` and assert the emitted event's data through the event store; do not force an artificial command into the design.

The default process stream is named from the class and correlation ID. Renaming a persisted process, changing `fetch_id`, or changing the meaning of historical events can orphan or invalidate existing history. Agree on compatibility handling before making such changes; do not silently start a new history.

### 4. Wire subscriptions

Add the process to the target app's configuration, following its existing entry point. In the main Rails app, add and call an `enable_*_process` method in `Processes::Configuration`:

```ruby
def enable_order_acceptance_process(event_store, command_bus)
  event_store.subscribe(
    OrderAcceptance.new.with(event_store: event_store, command_bus: command_bus),
    to: OrderAcceptance.subscribed_events
  )
end
```

Use `.subscribed_events` as the source of truth for stateful subscriptions. For plain subscribers, pass the explicit event list to `event_store.subscribe`. Verify that the app's `lib/configuration.rb` invokes its process configuration; do not register the same subscriber twice.

Process unit tests call the process directly, so they do not prove application wiring. Add or extend an integration scenario that exercises the real application entry point and observes the resulting business behavior. Prefer HTTP/UI interactions; commands are a temporary fallback when no UI exists. Do not use the event store or ActiveRecord directly in integration tests.

When working under `/new-feature`, keep dormant process slices green and deliver the end-to-end integration scenario with the final user-visible wiring slice.

### 5. Register architecture and mutation coverage

For a new process in the main Rails app:

- Add its namespace and owned file paths to `config/architecture.yml` under `processes`.
- Add its file stem to `process_paths` in the repository-root `Archspec.rb`, including any owned helper files as appropriate.
- Verify that `.mutant.yml` includes the process namespace and the test's `cover` expression matches it. `Processes*` already covers new classes in that namespace; do not add redundant matcher entries.
- Do not copy legacy mutation exclusions or baseline new architecture violations just to make checks pass. Resolve uncovered behavior and dependencies first.

For another app, inspect its existing architecture and mutation setup rather than copying the main app's configuration blindly.

### 6. Verify

After the focused red/green cycle, run from the target app directory:

1. `bin/rails test test/integration/` — integration behavior remains intact.
2. `bin/rails test test/processes/` — process contracts pass.
3. `make test` — the app suite passes.
4. `RAILS_ENV=test bundle exec mutant run 'Processes::YourProcess*'` — replace the matcher with each affected process namespace; require 100% mutation coverage.
5. In the main Rails app, run `make architecture` and `make archspec`.

Run repository-root `make test` before committing a completed slice. Report actual results and coverage, not just that commands ran. Do not add ignores to conceal surviving mutations.

If the change breaks persisted data or events used by `apps/rails_application`, remind the user to run the **Reset demo database** GitHub Actions workflow and warn that it deletes all demo data. Never run it without explicit approval.

## Key conventions

- Test-first TDD: input events → issued commands, including no-command cases.
- All calls are synchronous.
- Application processes coordinate; domains own commands and invariants; read models project data for queries.
- Use `event.data.fetch(:key)`, never bracket access for required event data.
- No comments in code or tests; assertions use parentheses.
- Follow the target app's style, preferring methods over local variables and avoiding named arguments unless the API requires them.
- Require green integration tests, architecture checks, and 100% mutation coverage for changed processes.
