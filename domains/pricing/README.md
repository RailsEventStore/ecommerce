# Pricing

[![Build Status](https://github.com/RailsEventStore/cqrs-es-sample-with-res/workflows/pricing/badge.svg)](https://github.com/RailsEventStore/cqrs-es-sample-with-res/actions/workflows/pricing.yml)

The `Pricing::Coupon` aggregate manages the creation and usage of a coupon. This includes as of now:

- registration

After each successful action an appropriate event is published in the Coupon stream.

|     Command     | Event | Service used to apply |
|:---------------:|:-----:|:----------------------|
| RegisterCoupon  | CouponRegistered | OnCouponRegister |

## Captured item prices

Commands are unchanged. Item events now contain only `price`, the captured unit
price before offer discounts. Items do not recalculate their prices when offer
discounts change. Removal chooses the cheapest captured unit price, even when the
offer has a 100% discount. Historical item payloads are not supported; no
compatibility adapters or migrations are provided.

The Rails total-value process applies discounts to the basket separately and sends
discounted product totals to invoicing.

#### Up and running

```
make install test mutate
```
