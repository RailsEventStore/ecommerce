# Payments

[![Build Status](https://github.com/RailsEventStore/cqrs-es-sample-with-res/workflows/payments/badge.svg)](https://github.com/RailsEventStore/cqrs-es-sample-with-res/actions/workflows/payments.yml)

The `Payments::Payment` aggregate manages the following states:

- authorized
- captured
- released

This Payment object is fully event sourced.

#### Up and running

```
make install test mutate
```
