# cqrs-es-sample-with-res

CQRS with Event Sourcing sample app using [Rails Event Store](https://railseventstore.org). See it [live](https://cqrs-es-sample-with-res.herokuapp.com/).

![Build Status](https://github.com/RailsEventStore/cqrs-es-sample-with-res/workflows/ci/badge.svg)
[![Maintainability](https://api.codeclimate.com/v1/badges/c444add86606b981e1fb/maintainability)](https://codeclimate.com/github/RailsEventStore/cqrs-es-sample-with-res/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/c444add86606b981e1fb/test_coverage)](https://codeclimate.com/github/RailsEventStore/cqrs-es-sample-with-res/test_coverage)


[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

# Order management app

This application simulates a process of managing orders.

We start with a list of exiting products and customers (populated with seeds).

## UI flow

- Add/remove some of the existing products to the order
- Choose the customer
- Submit the order 
  - after this you can't update the order items or customer
  - it generates the order number like "2021/03/20" (the last part is random(100))
- Look at the order
- Look at the history of events (in the Rails Event Store Browser)

## Domains

Domains exist in directories at the root level of the Rails app.

### Ordering

The `Ordering::Order` aggregate manages the state machine of an order:
- draft
- submitted
- paid
- expired

After each successful change an appropriate event is published in the Order stream.
This object is fully event sourced.

### Payments

The `Payments::Payment` aggregate manages the following states:
- authorized
- captured
- released
This object is fully event sourced.

## Read models

There's only one read model - which helps us listing all the orders 
and individual order details.

It consists of 2 ActiveRecord classes: `Order` and `OrderItem`.

## Process Managers

### 1. Release payments when order expired

There's a process manager responsible for dealing with the process of 
expiring orders.

It takes the following events as the input:
- Ordering::OrderSubmitted
- Ordering::OrderExpired
- Ordering::OrderPaid
- Payments::PaymentAuthorized
- Payments::PaymentReleased

When certain conditions are met the process manager return a 
`ReleasePayment` command.

### 2. Confirm order when payment successful

Another process manager is responsible for confirming order.
It does it, when a successful payment is detected. 