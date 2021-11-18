# ecommerce

Application with CQRS and Event Sourcing built on Rails and [Rails Event Store](https://railseventstore.org).

👉 [ecommerce.arkademy.dev](https://ecommerce.arkademy.dev)

[![imgur](https://imgur.com/ymJeLnP.png)](https://ecommerce.arkademy.dev)
## Domains

Domains exist in directories starting at [ecommerce](/ecommerce).

```
ecommerce/
├── crm
├── inventory
├── ordering
├── payments
├── pricing
└── product_catalog
└── shipping
```

Each one has a README introduction:

* [CRM](ecommerce/crm/README.md)
* [Inventory](ecommerce/inventory/README.md)
* [Ordering](ecommerce/ordering/README.md)
* [Payments](ecommerce/payments/README.md)
* [Pricing](ecommerce/pricing/README.md)
* [Product Catalog](ecommerce/product_catalog/README.md)
* [Shipping](ecommerce/shipping/README.md)

## Application

Order management application lives at [rails_application](/rails_application) directory.

This application simulates a process of managing orders.

We start with a list of exiting products and customers (populated with seeds).

### UI flow

#### Customer perspective

The customer perspective is "simulated" only - via using the select box.

- Add/remove some of the existing products to the order
- Choose the customer
- Submit the order
  - after this you can't update the order items or customer
  - it generates the order number like "2021/03/20" (the last part is random(100))
- Look at the order
- Look at the history of events (in the Rails Event Store Browser)

### Read models

There's only one read model - which helps us listing all the orders
and individual order details.

It consists of 2 ActiveRecord classes: `Order` and `OrderItem`.

### Process Managers

#### Release payments when order expired

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

#### Confirm order when payment successful

Another process manager is responsible for confirming order.
It does it, when a successful payment is detected.


# The Big Vision

This project has several high-level goals:

- to show that it's possible to modularize a non-trivial Rails app
- to serve as an example of a DDD project (not only in Rails)
- to let people play with this codebase to get a feel if DDD is for them
- to show that tests can be fast if the app is well modularized
- to show a proper pyramid of tests
- to teach event-driven architectures
- to show how to use RailsEventStore
- to bring DDD enthusiasts from .Net/Java/PHP/others to the Ruby world 😎
- to popularize professional testing techniques - mutation testing
- to allow programmers to reuse existing and popular domains
- to build new apps like Lego 

# Contributing guide

We welcome all the contributors here. 

As you see, this project is not an usual Rails project. 
Many Rails conventions are not followed here. Usually there's a good reason for that.
Trust us, but feel free to challenge our decisions.

Things worth knowing about:

- Zeitwerk is not used here - you need to be explicit with requires
- Any IDE should work with this codebase
- We use mutant for mutation testing, code that is untested breaks the build.
- But sometimes we allow ourselves for mutant ignores (explicit mark for mutant to ignore)
- Mutant ignores are considered technical debt.
- REST is not followed here for routes, no need for that
- `register_command` accepts events because it's used in the `/architecture` view. 
  It's a visualisation/documentation of the events flow
- Certain ideas are in the Work In Progress status - sorry about that
- Feel free to ask.
- After you make a contribution, we'll invite you to a special Discord
- Contributing is a good way to learn DDD/CQRS/Event sourcing.

## I like it, where can I learn more about all those DDD concepts?

Over time we have developed a number of DDD-related online courses. We now sell them as part of one membership access via [arkademy.dev](https://arkademy.dev) for $49/month.
