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
basket raises `IsEmpty`; a nonempty basket issues `AcceptOffer.new(order_id)`.
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
subscribers. An empty-order error rolls back the request rather than recording a
durable refusal. After refilling the basket, the user must request acceptance again.

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
