---
name: upgrade-rails
description: Upgrade Rails framework to a newer version following the smooth upgrade methodology
---

# Upgrade Rails

## When to use

Use this skill when upgrading Rails to a newer minor or patch version.

## Background

Based on the [Smooth Ruby and Rails Upgrades](https://blog.arkency.com/smooth-ruby-and-rails-upgrades/) methodology. Key principles:

- **Move by minor versions** — upgrade incrementally through each minor version to the latest patch, never skip minors
- **Separate Ruby and Rails upgrades** — never combine them in one step
- **Backport-first** — preparatory commits (gem updates, deprecation fixes) land on main first, then the version bump is a small final step
- **Small, reversible changes** — each commit leaves tests green and is independently deployable

## Upgrade strategy

For a Rails upgrade from e.g. 7.0.x to 7.2.x:
1. 7.0.x → 7.0.latest (patch only)
2. 7.0.latest → 7.1.latest (minor bump)
3. 7.1.latest → 7.2.latest (minor bump)

Never jump multiple minors at once.

## Upgrade process

### 1. Pre-flight checks

```bash
cd apps/rails_application
bundle outdated rails
rails -v
```

Check current version, target version, and plan the minor-version steps.

### 2. Audit dependencies before the bump

```bash
bundle exec bundler-audit check --update
```

Address any CVEs in separate preparatory commits. Then attempt the update to see if gems conflict:

```bash
bundle update rails --conservative
```

If gems conflict, update blocking gems first in separate commits on main.

### 3. Fix deprecation warnings first

Run the full test suite and grep for deprecation warnings:

```bash
make test 2>&1 | grep -i deprecat
```

Fix each deprecation in its own commit, deployed to main before the version bump. This is the backport-first approach — preparatory work lands independently.

### 4. Update the Rails version constraint

In `apps/rails_application/Gemfile`, update:
```ruby
gem "rails", "~> X.Y.0"
```

Then:
```bash
cd apps/rails_application
bundle update rails --conservative
```

Use `--conservative` to minimize collateral gem updates.

### 5. Run the full test suite

```bash
make test
```

Integration tests are the most critical — they exercise the full HTTP stack. Fix any failures before proceeding.

### 6. Check for deprecation warnings in the new version

```bash
make test 2>&1 | grep -i deprecat
```

Note these for fixing before the next minor bump.

### 7. Commit the version bump

Use the /commit skill. Good message example: "Upgrade Rails from 8.0.3 to 8.1.3"

### 8. Bump config.load_defaults (separate commit)

Bump `config.load_defaults` in `config/application.rb` to the new minor version. Before bumping:

1. Check the new defaults (search for `new_framework_defaults_X_Y.rb` in Rails source)
2. Grep the codebase for patterns that could break (e.g. unscoped `.first`/`.last` for `raise_on_missing_required_finder_order_columns`, path-relative redirects)
3. Bump, run `make test`, commit separately

### 9. (Optional) Run rails app:update

For minor version bumps, Rails provides an update task:

```bash
bin/rails app:update
```

This project has minimal Rails config surface (event-sourced architecture), so this is often unnecessary. Only run if the upgrade guide mentions config changes that matter.

## Key areas to verify if tests fail

- `config/application.rb` — load_defaults, config changes
- `config/environments/*.rb` — new or changed settings
- `config/initializers/` — framework initializers that may need updating
- `bin/` scripts — may need regeneration
- Asset pipeline / CSS / JS tooling — often changes between minors

## Important notes

- Always keep Ruby and Rails upgrades separate
- If a gem blocks the upgrade, update that gem first in a separate commit
- Each step must leave the test suite green
- Check [stdgems.org](https://stdgems.org) when upgrading Ruby (separate from this skill)
