---
name: upgrade-res
description: Upgrade RailsEventStore (RES) gems to a newer version
---

# Upgrade RailsEventStore (RES)

## When to use

Use this skill when upgrading RES gems (rails_event_store, ruby_event_store, aggregate_root, etc.) to a newer version.

## Background

RES is deeply integrated into this project. All gems must be upgraded together since they share a version. The dependency chain is:

- `rails_event_store` (Gemfile in rails_application) — top-level Rails integration
- `ruby_event_store` (infra.gemspec) — core event store
- `aggregate_root` (infra.gemspec) — aggregate root pattern
- `ruby_event_store-active_record` — AR repository (transitive)
- `ruby_event_store-browser` — event browser UI (transitive)
- `ruby_event_store-transformations` — type transformations (infra.gemspec, no version pin)
- `arkency-command_bus` — command bus (infra.gemspec, no version pin)

## Version constraints live in two places

1. `apps/rails_application/Gemfile` — `rails_event_store` with range constraint
2. `infra/infra.gemspec` — `aggregate_root` and `ruby_event_store` with pessimistic constraint

Both must allow the target version or be updated first.

## Upgrade process

### 1. Check current and target versions

```bash
cd apps/rails_application
bundle outdated | grep -iE "event|aggregate"
```

### 2. Check release notes for breaking changes

Visit https://github.com/RailsEventStore/rails_event_store/releases and review all versions between current and target. Pay attention to:
- Removed methods or changed signatures
- New required migrations
- Changed configuration API
- Deprecated features becoming errors

### 3. Update version constraints if needed

If the target version is outside current constraints:
- Update `infra/infra.gemspec` — change `~> X.Y` for `aggregate_root` and `ruby_event_store`
- Update `apps/rails_application/Gemfile` — change range for `rails_event_store`

### 4. Run bundle update

```bash
cd apps/rails_application
bundle update rails_event_store ruby_event_store aggregate_root ruby_event_store-active_record ruby_event_store-browser
```

This updates both the rails_application Gemfile.lock AND infra's resolved versions (infra is a path gem).

### 5. Check if infra/Gemfile.lock also needs updating

The infra gem has its own Gemfile.lock for isolated testing:

```bash
cd infra
bundle update ruby_event_store aggregate_root
```

### 6. Run the full test suite

```bash
make test
```

Integration tests are the most important — they exercise the full RES stack including AR persistence, event subscriptions, and process managers.

### 7. Check for deprecation warnings

Look for deprecation warnings in test output. Address them before they become errors in future versions.

### 8. Key integration points to verify

If tests pass, these are the areas most likely to break on API changes:

- `infra/lib/infra/event_store.rb` — EventStore wrapper, mapper pipeline, preserve_types
- `infra/lib/infra/event.rb` — Event base class extending RubyEventStore::Event
- `infra/lib/infra/aggregate_root_repository.rb` — AggregateRoot::Repository wrapper
- `infra/lib/infra/process_manager.rb` — ProcessManager using event_store.read/link
- `infra/lib/infra/process.rb` — Simple event-to-command process
- `apps/rails_application/config/initializers/rails_event_store.rb` — RES initialization
- `apps/rails_application/lib/configuration.rb` — LinkByEventType, LinkByCorrelationId, LinkByCausationId

### 9. Historical gotchas from past upgrades

- **RES 2.0**: Required 3 database migrations (timestamp precision, valid_at column, stream restructuring)
- **ProcessManager API**: Changed from constructor-based subscription to declarative `subscribes_to`
- **Mapper pipeline**: Changed multiple times; the project wraps it in `Infra::EventStore` to isolate changes
- **In-memory vs production divergence**: Transformations were removed from in-memory stores to prevent test issues
- **Class-level state**: Was removed in favor of dependency injection; watch for similar patterns

### 10. Commit

Use the /commit skill. Good message example: "Upgrade RailsEventStore from 2.17.1 to 2.18.0"
