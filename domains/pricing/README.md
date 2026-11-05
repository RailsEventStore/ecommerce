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

`AcceptOffer.new(order_id, item_count)` requires the current number of units from
the application's existing order projection. `Offer` rejects a zero count and
acceptance outside the draft state. It does not reload lines to verify the supplied
count, and `OfferAccepted` contains only `order_id`.

Rails and Hanami derive the count from their projected line quantities, without
replaying events. Item commands and their synchronous subscribers must share a
transaction so that failed edits do not leave the projection behind the line stream.
The existing Rails submit transaction also contains the count query.

Old `Offer` streams containing item events are not supported. Reset demo data after
deploying this change; no compatibility migration is provided. The split bounds
the pricing aggregate to one product line, not the event-sourced processes that
still reconstruct the whole basket.

#### Up and running

```
make install test mutate
```
