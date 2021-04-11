# cqrs-es-sample-with-res

CQRS with Event Sourcing sample app using [Rails Event Store](https://railseventstore.org). See it [live](https://cqrs-es-sample-with-res.herokuapp.com/).

[![Build Status](https://github.com/RailsEventStore/cqrs-es-sample-with-res/workflows/ci/badge.svg)](https://github.com/RailsEventStore/cqrs-es-sample-with-res/actions/workflows/ci.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/c444add86606b981e1fb/maintainability)](https://codeclimate.com/github/RailsEventStore/cqrs-es-sample-with-res/maintainability)

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

# Order management app

This application simulates a process of managing orders.

We start with a list of exiting products and customers (populated with seeds).

## Setup

### Postgresql

#### Docker

If you would like to use Docker image with PostgreSQL provided by us, run `docker-compose up -d`. Your done for this
step.

#### PostgreSQL installed in the system

If you have PostgreSQL installed directly in your system and prefer to use it, create

- `.env.development.local`
  containing:

```
DATABASE_URL=postgresql:///cqrs-es-sample-with-res_development
```

* `.env.test.local` containing:

```
DATABASE_URL=postgresql:///cqrs-es-sample-with-res_test
```

It should would work for most of the cases. If you have more sophisticated setup, you need to update `DATABASE_URL`
accordingly.

### Application

Run `make dev` to install dependencies, create db, setup schema and seed data.

Run `bin/rails s` to start the web server.

## UI flow

### Customer perspective

The customer perspective is "simulated" only - via using the select box.

- Add/remove some of the existing products to the order
- Choose the customer
- Submit the order 
  - after this you can't update the order items or customer
  - it generates the order number like "2021/03/20" (the last part is random(100))
- Look at the order
- Look at the history of events (in the Rails Event Store Browser)

### Admin perspective

In `/admin` we show how to combine the `ActiveAdmin` gem with the
DDD/event-driven approach. We do it via limiting the typical CRUD actions. 
All the "view" options are still there. 

Admin can cancel an order in the admin panel.

## Domains

Domains exist in directories at the root level of the Rails app.

### Ordering

The `Ordering::Order` aggregate manages the state machine of an order:
- draft
- submitted
- paid
- expired
- cancelled

After each successful change an appropriate event is published in the Order stream.
This object is fully event sourced.

| Order     | draft | submitted | paid  | expired  | cancelled |
|-----------|:-----:|:---------:|:-----:|:--------:|:---------:|
| draft     |       |     ✅    |       |   ✅      |           |
| submitted |       |           |   ✅  |          |   ✅       |
| paid      |       |           |       |          |           |
| expired   |       |           |       |          |           |
| cancelled |       |           |       |          |           |

### Payments

The `Payments::Payment` aggregate manages the following states:
- authorized
- captured
- released

This Payment object is fully event sourced.

### Product Catalog

We implement this domain as a CRUD-based bounded context. The goal is to present
how to deal with such CRUD-ish domains and to show how to integrate it with 
parts of the system.

It's just a single ActiveRecord `Product` class.

We wrap it with a `ProductCatalog` namespace to explicitly set its boundaries.

This Bounded Context has both - the write part and the read part as the 
same model. You can say it's not really CQRS - which is true for many CRUDish
bounded contexts. 

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

# I like it, where can I learn more about all those DDD concepts?

Over time we have developed a number of DDD-related online courses. We now sell them as part of 1 membership access via [https://arkademy.dev](https://arkademy.dev) for $49/month.
