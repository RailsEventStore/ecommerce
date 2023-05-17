# ecommerce

A non-trivial application with DDD, CQRS and Event Sourcing built on Rails and [Rails Event Store](https://railseventstore.org).

👉 [ecommerce.arkademy.dev](https://ecommerce.arkademy.dev)

[![imgur](https://imgur.com/ymJeLnP.png)](https://ecommerce.arkademy.dev)
## Domains

Event storming (events and commands) - [Miro documentation](https://miro.com/app/board/o9J_l7eqFP0=/)

Domains exist in directories starting at [ecommerce](/ecommerce).

```
ecommerce/
├── crm
├── inventory
├── invoicing
├── ordering
├── payments
├── pricing
├── processes
├── product_catalog
├── shipping
└── taxes
```

(almost) Each one has a README introduction:

* [CRM](ecommerce/crm/README.md)
* [Inventory](ecommerce/inventory/README.md)
* [Invoicing](ecommerce/invoicing/README.md)
* [Ordering](ecommerce/ordering/README.md)
* [Payments](ecommerce/payments/README.md)
* [Pricing](ecommerce/pricing/README.md)
* [Processes](ecommerce/processes/README.md)
* [Product Catalog](ecommerce/product_catalog/README.md)
* [Shipping](ecommerce/shipping/README.md)
* [Taxes](ecommerce/taxes/README.md)

## Application

Order management application lives at [rails_application](/rails_application) directory.

This application simulates a process of managing orders.

We start with a list of exiting products, customers and coupons (populated with seeds).

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

Read models live at the application level. In our case it's in the Rails app:

[Read models](https://github.com/RailsEventStore/ecommerce/tree/master/rails_application/app/read_models)

### Process Managers

#### Release payments when order expired

There's a process manager responsible for dealing with the process of
expiring orders.

It takes the following events as the input:
- Ordering::OrderSubmitted
- Ordering::OrderExpired
- Ordering::OrderConfirmed
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

**Code comments**

Do not leave comments in the code by default. Just leave an GitHub issue instead of a TODO comment for example.

**Technical debt**

One of the goals of this project is educational - to show how to implement certain features with DDD.
As such we treat the actual code as business value.
That's why (as opposed to "normal" projects") we can treat technical debt as part of the "backlog".

Whenever you add a temporary hack to the codebase, add a Github issue - maybe someone else will be able to help or clean.
When you work on certain are and see some not pretty code - fix it or create an issue and add the "debt" label.

**Backlog**

If you're somehow experienced with ecommerce (even when not as a dev) - your experience can help us. 
Please create new Github issues with features that can exist in typical ecommerces. 
Our goal is to cover as many features as possible - especially the tricky ones.

If you're a developer working on ecommerce and you want to learn how to implement a specific feature - feel free to add this as a ticket too.

All tickets should bring business value and be consistent with previous features.
It's fine to create vague tickets at the beginning and let them be more specific later. 

**Local setup**

As for the local dev setup:

- we use Makefile, so `make install` should simplify a lot
- to start the web application and all the workers type `make dev`
- there's docker-compose in the rails_application, if you're into Docker
- Ruby version, it's best to use the same, which we use for CI/production: [as defined in this file](https://github.com/RailsEventStore/ecommerce/blob/master/.github/workflows/rails_application.yml#L31)

**Bundler note**

Please check that your bundler version is not ancient, and up to date. For more details check:
`git show 6dc6e1c2ea833e1ea5821cc9bc9bd5dfadbfda9a` which explains the problem and proposes a solution.
A sign that you have a problem will be unusual changes in `Gemfile.lock` i.e. changes in remote sources and placement of gems definitions.

Things worth knowing about:

- Zeitwerk is not used here - you need to be explicit with requires
- Any IDE should work with this codebase
- We use mutant for mutation testing, code that is untested breaks the build.
- But sometimes we allow ourselves for mutant ignores (explicit mark for mutant to ignore)
- Mutant ignores are considered technical debt.
- REST is not followed here for routes, no need for that
- Certain ideas are in the Work In Progress status - sorry about that
- Feel free to ask.
- We keep domains/BC code decoupled from each other - with the long term goal of reusability.
- After you make a contribution, we'll invite you to a special Discord
- Contributing is a good way to learn DDD/CQRS/Event sourcing.

## Discord

There's a Discord server connected with RailsEventStore and with this Ecommerce project.
Feel free to join [here](https://discord.gg/2xDJPgPjc8) to ask questions or discuss the vision.

## I like it, where can I learn more about all those DDD concepts?

Over time we have developed a number of DDD-related online courses. We now sell them as part of one membership access via [arkademy.dev](https://arkademy.dev).
