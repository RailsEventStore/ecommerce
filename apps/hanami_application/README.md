# Hanami application

A minimal cart built with [Hanami 3](https://hanakai.org) on top of **RubyEventStore** (no Rails, no ActiveRecord), reusing the bounded contexts from [domains/](../../domains):

- `product_catalog` — registering and naming products
- `pricing` — the `Offer` aggregate acts as the cart (`DraftOffer`, `AddPriceItem`, `AcceptOffer`)
- `fulfillment` — `RegisterOrder` and `ConfirmOrder`

## The flow

Pick a product, add it to the cart, submit the order. Submitting sends `Pricing::AcceptOffer`; the `OrderFulfillment` process reacts to `OfferAccepted` with `Fulfillment::RegisterOrder`, then to `OrderRegistered` with `Fulfillment::ConfirmOrder`. All handlers run synchronously, so the order page already shows the delivery confirmation.

## The wiring

Everything is wired with Hanami providers ([config/providers](config/providers)):

- `db` — [hanami-db](https://github.com/hanami/hanami-db) (ROM/Sequel) with SQLite; migrations for the event store and read model tables live in [config/db/migrate](config/db/migrate) and are managed by `hanami db prepare`
- `event_store` — a `RubyEventStore::Client` on `RubyEventStore::Sequel::EventRepository`, borrowing the Sequel connection from `db.gateway`
- `command_bus` — `Arkency::CommandBus` with each domain's `Configuration` registered against it
- `read_models` — read models ([app/read_models](app/read_models)) projecting domain events into the `products`, `orders` and `order_lines` tables through ROM relations ([app/relations](app/relations)); registered as `read_models.catalog` and `read_models.orders`
- `processes` — the `OrderFulfillment` process manager
- `seeds` — seeds the catalog with a few products, skipped when the catalog already has any

Actions and views resolve these through `Deps`, e.g. `include Deps["command_bus", "read_models.catalog"]`. The current cart id lives in the (cookie) session.

## Persistence

Events are persisted to SQLite via `ruby_event_store-sequel`, and read models are persisted alongside them: event handlers project into regular tables through ROM relations, just like the Rails app projects into ActiveRecord models. Everything survives restarts. The event store client uses the same mapper as the Rails app's `RailsEventStore::JSONClient` (`Infra::EventStore.default_mapper`), so `BigDecimal` prices and symbol keys round-trip through JSON.

The database URL defaults to `sqlite://db/hanami_application_<env>.sqlite` in [config/providers/db.rb](config/providers/db.rb) and can be overridden with `DATABASE_URL`. Tests get a fresh database on every run ([test/test_helper.rb](test/test_helper.rb) deletes it and runs `hanami db prepare`).

## Gotchas vs the Rails application

- `Infra::EventStore.main` hard-codes `RailsEventStore::JSONClient`, so this app builds its own `RubyEventStore::Client` on the Sequel repository instead.
- The `infra` gem requires `active_support` and `minitest` without declaring them in its gemspec (Rails provides them for free elsewhere), so they are explicit dependencies in this app's [Gemfile](Gemfile).
- Read models must subscribe before process managers: handlers run synchronously in subscription order, and the `OrderFulfillment` process publishes follow-up events inline. That's why the `processes` provider starts `read_models` first.
- `hanami db` shells out to the `sqlite3` CLI for create/dump, so it must be installed (`apt-get install sqlite3` / `brew install sqlite`).

## Running

```
make install
bundle exec hanami dev
```

Then visit http://localhost:2300.

## Tests

```
make test
```
