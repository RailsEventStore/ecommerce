# Hanami application

A minimal cart built with [Hanami 3](https://hanakai.org) on top of **RubyEventStore** (no Rails, no ActiveRecord), reusing the bounded contexts from [domains/](../../domains):

- `product_catalog` — registering and naming products
- `pricing` — the `Offer` aggregate acts as the cart (`DraftOffer`, `AddPriceItem`, `AcceptOffer`)
- `fulfillment` — `RegisterOrder` and `ConfirmOrder`

## The flow

Pick a product, add it to the cart, submit the order. Submitting sends `Pricing::AcceptOffer`; the `OrderFulfillment` process reacts to `OfferAccepted` with `Fulfillment::RegisterOrder`, then to `OrderRegistered` with `Fulfillment::ConfirmOrder`. All handlers run synchronously, so the order page already shows the delivery confirmation.

## The wiring

Everything is wired with Hanami providers ([config/providers](config/providers)):

- `event_store` — `Infra::EventStore.in_memory` (a `RubyEventStore::Client` with `InMemoryRepository`)
- `command_bus` — `Arkency::CommandBus` with each domain's `Configuration` registered against it
- `read_models` — in-memory read models ([app/read_models](app/read_models)) subscribed to domain events, registered as `read_models.catalog` and `read_models.orders`
- `processes` — the `OrderFulfillment` process manager
- `seeds` — seeds the catalog with a few products at boot

Actions and views resolve these through `Deps`, e.g. `include Deps["command_bus", "read_models.catalog"]`. The current cart id lives in the (cookie) session.

## Gotchas vs the Rails application

- `Infra::EventStore.main` hard-codes `RailsEventStore::JSONClient`, so this app uses `Infra::EventStore.in_memory`. Events are not persisted: restart the server and the shop is fresh again. For persistence, `ruby_event_store-sequel` would pair well with `hanami-db` (ROM/Sequel).
- The `infra` gem requires `active_support` and `minitest` without declaring them in its gemspec (Rails provides them for free elsewhere), so they are explicit dependencies in this app's [Gemfile](Gemfile).
- The in-memory event store and read models live in a single process; run the server single-process (the default).
- Read models must subscribe before process managers: handlers run synchronously in subscription order, and the `OrderFulfillment` process publishes follow-up events inline. That's why the `processes` provider starts `read_models` first.

## Running

```
bundle install
bundle exec hanami dev
```

Then visit http://localhost:2300.

## Tests

```
make test
```
