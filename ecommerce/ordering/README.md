# Ordering

[![Build Status](https://github.com/RailsEventStore/cqrs-es-sample-with-res/workflows/ordering/badge.svg)](https://github.com/RailsEventStore/cqrs-es-sample-with-res/actions/workflows/ordering.yml)

The `Ordering::Order` aggregate manages the state machine of an order:

- draft
- submitted
- accepted
- expired

After each successful change an appropriate event is published in the Order stream.
This object is fully event sourced.

| Order     | draft | expired | submitted | accepted | 
|-----------|:-----:|:-------:|:---------:|:--------:|
| draft     |       |    ✅    |     ✅     |          |
| expired   |       |         |           |          |
| submitted |   ✅   |         |           |    ✅     |
| accepted  |       |         |           |          |

### Design dilemmas

#### God Domain

The state machine mentioned above became a very central place to the whole application.
Almost every other domain either reacts to this domain or triggers Ordering.

This might be an issue, as we might end up with a God Domain.

#### Duplication of states

Some of the states here are actually duplicates of the states of the Order in other domains.

#### Multiplication and naming of states

We clearly have a naming issue here.
What is the actual difference between submit/confirm/accept?
Not all the names match between method names and event names.

#### Order items

We track order items here, but we actually don't really use it much.
It doesn't have any impact on the state machine.
It's only needed to some read models, which can retrieve it from elsewhere - most notably the `Pricing`
The implementation of `Basket`, because of this, seems duplicated to Pricing or Inventory.

#### Mapping of events between domains

UI -> Ordering::SubmitOrder -> Ordering::Submitted -> Reservation(process) -> Ordering::AcceptOrder

Ordering::AcceptOrder -> Ordering::OrderPlaced ->

-> Shipment::SubmitShipment
-> Pricing::CalculateTotalValue

### Up and running

```
make install test mutate
```
