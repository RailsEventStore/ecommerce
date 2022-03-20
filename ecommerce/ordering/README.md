# Ordering

[![Build Status](https://github.com/RailsEventStore/cqrs-es-sample-with-res/workflows/ordering/badge.svg)](https://github.com/RailsEventStore/cqrs-es-sample-with-res/actions/workflows/ordering.yml)

The `Ordering::Order` aggregate manages the state machine of an order:

- draft
- submitted
- confirmed
- expired
- cancelled

After each successful change an appropriate event is published in the Order stream.
This object is fully event sourced.

| Order     | draft | submitted | confirmed | expired | cancelled |
| --------- | :---: | :-------: | :--:      | :-----: | :-------: |
| draft     |       |    ✅     |           |   ✅    |           |
| submitted |       |           |  ✅       |         |    ✅     |
| confirmed |       |           |           |         |           |
| expired   |       |           |           |         |           |
| cancelled |       |           |           |         |           |

#### Up and running

```
make install test mutate
```
