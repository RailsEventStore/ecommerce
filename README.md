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
```

Each one has a README introduction:

* [CRM](ecommerce/crm/README.md)
* [Inventory](ecommerce/inventory/README.md)
* [Ordering](ecommerce/ordering/README.md)
* [Payments](ecommerce/payments/README.md)
* [Pricing](ecommerce/pricing/README.md)
* [Product Catalog](ecommerce/product_catalog/README.md)


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



## I like it, where can I learn more about all those DDD concepts?

Over time we have developed a number of DDD-related online courses. We now sell them as part of one membership access via [arkademy.dev](https://arkademy.dev) for $49/month.
