---
name: new-feature
description: Plan a new feature end-to-end — impact analysis across all layers before delegating to /domain, /read-model, /controller skills
---

# New Feature

## When to use

Use this skill when asked to add a new user-facing feature. It ensures you think through **all affected layers upfront** before writing any code.

## What this skill does

This skill is a **planning and coordination** step. It does NOT contain implementation details — those live in `/domain`, `/read-model`, and `/controller`. This skill ensures you:

1. Identify everything that needs to change
2. Write a failing integration test that covers all affected surfaces
3. Then delegate implementation to the appropriate skills

## Step-by-step process

### 1. Impact analysis

Before writing any code, search for all consumers of the affected entity's data:

```bash
# Find all read models that subscribe to events from the same entity
grep -r "DomainModule::RelatedEvent" apps/rails_application/app/read_models/ -l

# Find all places that store the affected attribute
grep -r "affected_attribute" apps/rails_application/app/read_models/

# Find all views that display it
grep -r "affected_attribute" apps/rails_application/app/views/
```

**For each read model that stores the affected data, ask:**
1. Does it subscribe to the creation event for this entity?
2. Does it store or denormalize the attribute being changed?
3. If yes to both: it needs a handler for the new event.

**Common patterns requiring multi-read-model updates:**
- **Renaming** — entity names denormalized into other read models
- **Price changes** — prices snapshotted in order/deal read models
- **Status changes** — displayed across list views in different read models
- **Reassignment** — entity associations denormalized in multiple places

### 2. Produce a plan

List every change needed:
- **Domain:** new command, event, aggregate method, handler
- **Read models:** which read models need new event handlers (list each one)
- **Controller:** which actions change, new routes
- **Views:** which templates change

Present this plan to the user before proceeding.

### 3. Write the integration test first

The integration test must verify the feature works **across all affected UI surfaces**, not just the primary one.

Create enough related data (orders, deals, etc.) so that secondary pages also display the affected data. Then assert the change is visible on **every page that shows it**.

### 4. Delegate implementation

Use the existing skills:
- `/domain` — for commands, events, aggregates, handlers
- `/read-model` — for read model event handlers and configuration
- `/controller` — for controller actions, routes, views

### 5. Verify

1. Integration test passes
2. `rails test test/integration/` — all integration tests pass
3. `make test` — all tests green
4. Run mutant for affected namespaces

## Checklist

- [ ] Searched all read models for the affected entity's data
- [ ] Searched all views for display of the affected data
- [ ] Listed every read model that needs a new handler
- [ ] Integration test covers all affected pages
- [ ] Denormalized copies of data are updated (not just the primary table)
