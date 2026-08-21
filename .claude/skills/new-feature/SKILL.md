---
name: new-feature
description: Plan a new feature end-to-end — impact analysis across all layers, start-from-the-middle slicing into deployable steps, then delegating to /domain, /read-model, /controller skills
---

# New Feature

## When to use

Use this skill when asked to add a new user-facing feature. It ensures you think through **all affected layers upfront** before writing any code.

## What this skill does

This skill is a **planning and coordination** step. It does NOT contain implementation details — those live in `/domain`, `/read-model`, and `/controller`. This skill ensures you:

1. Identify everything that needs to change
2. Slice the work start-from-the-middle into releasable steps
3. Work test-first within each slice
4. Then delegate implementation to the appropriate skills

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

### 3. Slice the work — start from the middle

Reference: "Start from the middle" by Andrzej Krzywda
(http://andrzejonsoftware.blogspot.com/2015/09/start-from-middle.html)

Cut the plan into the **smallest vertical slices** that each keep the whole
suite green and are **independently deployable**. The slices must progress
toward the full plan from step 2 — the big picture stays fixed, only the
delivery is incremental.

**Finding the middle:** the middle is the riskiest or most essential decision
of the feature — usually the new domain behavior (commands, events, the rule
being enforced). The edges — real third-party adapters, imports, forms, UI
polish — come last or get faked.

Slicing rules:
- Each slice leaves the app releasable: green tests, no half-wired
  user-facing behavior. **Dormant code is fine** — an event handler or
  process manager nobody triggers yet is a free feature toggle in an
  event-driven system.
- **Fake the risky dependency first, integrate it later.** A fake gateway
  or fake client is a legitimate slice; the real adapter is a later slice.
- Default slice order: domain building blocks (dormant) → coordination
  (process managers, still dormant) → adapters/infrastructure → **the final
  slice flips the user-visible behavior** (controller/view wiring).
- One slice = one commit (see /commit). After each slice: run the tests,
  commit, present to the user for acceptance, and only then start the next
  slice.

Present the slice list to the user before implementing.

### 4. Write each slice's test first

Work test-first **per slice**: domain slices get domain tests, process
manager slices get process tests, adapter slices get unit tests with the
external call stubbed.

The end-to-end integration test must verify the feature works **across all
affected UI surfaces**, not just the primary one. Draft it early to define
"done", but it ships with the **final wiring slice** — every commit stays
green, so it cannot land red before the behavior exists.

Create enough related data (orders, deals, etc.) so that secondary pages also
display the affected data. Then assert the change is visible on **every page
that shows it**.

### 5. Delegate implementation

Use the existing skills:
- `/domain` — for commands, events, aggregates, handlers
- `/read-model` — for read model event handlers and configuration
- `/controller` — for controller actions, routes, views

### 6. Verify each affected read model individually

For **every** read model that was touched (not just the primary one):

1. Add or update **unit tests** in the read model's test file — the integration test is not enough, mutant requires unit-level coverage
2. Tests must use **multiple records** to kill `where`-clause removal mutations (e.g., two customers so renaming one doesn't affect the other)
3. If a lookup table is updated alongside denormalized records, test that subsequent operations (e.g., assign after rename) use the updated lookup value
4. Run mutant for each affected namespace:
   ```bash
   RAILS_ENV=test bundle exec mutant run "OrderHeader::RenameCustomer*"
   RAILS_ENV=test bundle exec mutant run "Deals::EventHandler*"
   ```
5. 100% mutation score required before moving on

### 7. Final verification

1. Integration test passes
2. `rails test test/integration/` — all integration tests pass
3. `make test` — all tests green
4. Mutant passes for all affected namespaces

## Checklist

- [ ] Searched all read models for the affected entity's data
- [ ] Searched all views for display of the affected data
- [ ] Listed every read model that needs a new handler
- [ ] Work sliced start-from-the-middle; slice list accepted by the user
- [ ] Each slice green, deployable, committed, and accepted before the next
- [ ] Integration test covers all affected pages
- [ ] Denormalized copies of data are updated (not just the primary table)
- [ ] **Unit tests added for every new/modified read model handler**
- [ ] **Mutant run for each affected read model namespace at 100%**
