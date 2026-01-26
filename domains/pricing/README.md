# Pricing

[![Build Status](https://github.com/RailsEventStore/cqrs-es-sample-with-res/workflows/pricing/badge.svg)](https://github.com/RailsEventStore/cqrs-es-sample-with-res/actions/workflows/pricing.yml)

The `Pricing::Coupon` aggregate manages the creation and usage of a coupon. This includes as of now:

- registration

After each successful action an appropriate event is published in the Coupon stream.

|     Command     | Event | Service used to apply |
|:---------------:|:-----:|:----------------------|
| RegisterCoupon  | CouponRegistered | OnCouponRegister |

#### Up and running

```
make install test mutate
```
