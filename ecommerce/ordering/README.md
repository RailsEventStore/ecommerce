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

### Design dilemmas


#### God Domain

The state machine mentioned above became a very central place to the whole application.
Almost every other domain either reacts to this domain or triggers Ordering.

This might be an issue, as we might end up with a God Domain.

#### Duplication of states

Some of the states here are actually duplicates of the states of the Order in other domains.

#### Multiplication and naming of states

We clearly have a naming issue here. 
What is the actual difference between presubmit/submit/confirm/accept?
Not all the names match between method names and event names.

#### Order items

We track order items here, but we actually don't really use it much. 
It doesn't have any impact on the state machine.
It's only needed to some read models, which can retrieve it from elsewhere - most notably the `Pricing`
The implementation of `Basket`, because of this, seems duplicated to Pricing or Inventory.

#### Checking availability in the controllers

```ruby
def add_item
    read_model = Orders::OrderLine.where(order_uid: params[:id], product_id: params[:product_id]).first
    if Availability::Product.exists?(["uid = ? and available < ?", params[:product_id], (read_model&.quantity || 0) + 1])
      redirect_to edit_order_path(params[:id]),
                  alert: "Product not available in requested quantity!" and return
    end
    ActiveRecord::Base.transaction do
      command_bus.(Ordering::AddItemToBasket.new(order_id: params[:id], product_id: params[:product_id]))
    end
    head :ok
  end
```

This code is duplicated for admin creating orders and clients creating orders.

#### Mapping of events between domains

UI -> Ordering::SubmitOrder -> Ordering::Presubmitted -> Reservation(process) -> Ordering::AcceptOrder

Ordering::AcceptOrder -> Ordering::OrderPlaced -> 

  -> Shipment::SubmitShipment
  -> Pricing::CalculateTotalValue


### Up and running

```
make install test mutate
```
