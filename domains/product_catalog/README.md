# Product Catalog

[![Build Status](https://github.com/RailsEventStore/cqrs-es-sample-with-res/workflows/product_catalog/badge.svg)](https://github.com/RailsEventStore/cqrs-es-sample-with-res/actions/workflows/product_catalog.yml)

We implement this domain as a CRUD-based bounded context. The goal is to present
how to deal with such CRUD-ish domains and to show how to integrate it with
parts of the system.

It's just a single ActiveRecord `Product` class.

We wrap it with a `ProductCatalog` namespace to explicitly set its boundaries.

This Bounded Context has both - the write part and the read part as the
same model. You can say it's not really CQRS - which is true for many CRUDish
bounded contexts.

#### Up and running

```
make install test mutate
```
