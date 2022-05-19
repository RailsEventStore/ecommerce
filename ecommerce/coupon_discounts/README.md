# Coupons

[![Build Status](https://github.com/RailsEventStore/cqrs-es-sample-with-res/workflows/ordering/badge.svg)](https://github.com/RailsEventStore/cqrs-es-sample-with-res/actions/workflows/ordering.yml)

The `CouponDiscounts::Coupon` aggregate manages the creation and usage of a coupon. This includes as of now:

- registration

After each successful action an appropriate event is published in the Coupon stream.
Its called CouponDiscounts instead Coupons since otherwise it would collide with ReadModel name, and that scope makes more sense there

|     Command     | Event | Service used to apply |
|:---------------:|:-----:|:----------------------|
| RegisterCoupon  | CouponRegistered | OnCouponRegister |

#### Up and running

```
make install test mutate
```
