# Pricing

[![Build Status](https://github.com/RailsEventStore/cqrs-es-sample-with-res/workflows/pricing/badge.svg)](https://github.com/RailsEventStore/cqrs-es-sample-with-res/actions/workflows/pricing.yml)

The `Pricing::Coupon` aggregate manages the creation and usage of a coupon. This includes as of now:

- registration

After each successful action an appropriate event is published in the Coupon stream.

|     Command     | Event | Service used to apply |
|:---------------:|:-----:|:----------------------|
| RegisterCoupon  | CouponRegistered | OnCouponRegister |

## Captured item prices

`AddPriceItem` and `RemovePriceItem` retain their arguments and operate on one
`OfferLine` per `order_id:product_id`. Each line has its own event stream; editing
it does not load or append to `Offer`. Item events contain only `price`, the captured unit
price before offer discounts. Items do not recalculate their prices when offer
discounts change. Removal chooses the cheapest captured unit price, even when the
offer has a 100% discount. Historical item payloads are not supported; no
compatibility adapters or migrations are provided.

The Rails total-value process applies discounts to the basket separately and sends
discounted product totals to invoicing.

## Offer acceptance

Applications submit `RequestOrderAcceptance.new(order_id)`. The small
`OrderAcceptance` aggregate records `OrderAcceptanceRequested` in its own stream,
without accepting the offer. Requests may be repeated after correcting the basket.

Each application owns an order acceptance process. In Rails,
`Processes::OrderAcceptance` builds its state from `PriceItemAdded` and
`PriceItemRemoved`. Only `OrderAcceptanceRequested` triggers a decision: an empty
basket issues `RejectEmptyOrderAcceptance.new(order_id)`; a nonempty basket issues
`AcceptOffer.new(order_id)`. The rejection command makes `OrderAcceptance` record
`EmptyOrderAcceptanceRejected`, with only `order_id` as its payload. This is a
refusal of acceptance, not `OfferRejected`, which reverses an already accepted offer.
Basket edits never trigger acceptance by themselves. The process uses its own
event stream, not the UI read models or aggregate streams.

Hanami's smaller process checks its existing order projection when the request
arrives. Neither application passes an item count to a command or aggregate.
Application-specific acceptance criteria belong in these processes.

`Offer` still guards its own lifecycle: only a draft can be accepted.
`OfferAccepted` still contains only `order_id`. Stock reservation and compensation
remain in the existing Rails reservation process. `AcceptOffer` is the process's
output, not an application entry point; calling it directly bypasses eligibility.

Item edits and acceptance requests must share a transaction with their synchronous
subscribers. An empty-order refusal commits both the request and rejection events
and leaves the offer in draft without assigning a customer. After refilling the
basket, the user must request acceptance again. Unexpected failures still roll back
the transaction.

Rails uses one `Orders::SubmitService` for both panels. It temporarily subscribes
with `event_store.within { ... }.subscribe(...).call`, captures the outcome for the
requested `order_id`, and returns the event after the transaction completes. The
outcomes are `EmptyOrderAcceptanceRejected`, `OfferRejected`, and
`Fulfillment::OrderRegistered`. Success is observed after stock reservation, not at
`OfferAccepted`, which can still lead to rejection. Controllers translate the event
into a redirect and UI message; domain events do not contain presentation text.
Hanami similarly captures an empty-order rejection around its submit command.

Temporary subscriptions observe the entire synchronous chain of nested commands
and events, and RubyEventStore removes them in an `ensure` block, including on an
unexpected exception. They are scoped to that invocation, not historical events;
the order ID filter also excludes other orders processed within it. This approach
depends on synchronous processing. A persisted submission-status read model would
be an alternative if the UI needed to retrieve outcomes in a later request.

Existing Rails baskets have no history in the new `Processes::OrderAcceptance`
streams. Reset the demo database after deploying this change; otherwise those
streams need their historical item events linked before acceptance is enabled.
No automatic backfill is provided. Like the existing basket processes, this process
replays its order history; splitting the aggregates does not bound that replay.

Old `Offer` streams containing item events are not supported. Reset demo data after
deploying this change; no compatibility migration is provided. The split bounds
the pricing aggregate to one product line, not the event-sourced processes that
still reconstruct the whole basket.

#### Up and running

```
make install test mutate
```
