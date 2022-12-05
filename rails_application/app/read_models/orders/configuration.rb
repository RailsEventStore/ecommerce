module Orders
  class Order < ApplicationRecord
    self.table_name = "orders"

    has_many :order_lines,
             -> { order(id: :asc) },
             class_name: "Orders::OrderLine",
             foreign_key: :order_uid,
             primary_key: :uid
  end

  class Product < ApplicationRecord
    self.table_name = "orders_products"
  end

  class Customer < ApplicationRecord
    self.table_name = "orders_customers"
  end

  class OrderLine < ApplicationRecord
    self.table_name = "order_lines"

    def value
      price * quantity
    end
  end

  class Configuration

    def call(event_store)
      @event_store = event_store

      Rails.configuration.broadcaster = Orders::Broadcaster.new

      event_store.subscribe(AddItemToOrder, to: [Ordering::ItemAddedToBasket])
      event_store.subscribe(RemoveItemFromOrder, to: [Ordering::ItemRemovedFromBasket])
      event_store.subscribe(UpdateDiscount, to: [Pricing::PercentageDiscountSet, Pricing::PercentageDiscountChanged])
      event_store.subscribe(ResetDiscount, to: [Pricing::PercentageDiscountReset])
      event_store.subscribe(UpdateOrderTotalValue, to: [Pricing::OrderTotalValueCalculated])
      event_store.subscribe(RegisterProduct, to: [ProductCatalog::ProductRegistered])
      event_store.subscribe(ChangeProductName, to: [ProductCatalog::ProductNamed])
      event_store.subscribe(ChangeProductPrice, to: [Pricing::PriceSet])
      event_store.subscribe(CreateCustomer, to: [Crm::CustomerRegistered])
      event_store.subscribe(AssignCustomerToOrder, to: [Crm::CustomerAssignedToOrder])
      event_store.subscribe(SubmitOrder, to: [Ordering::OrderSubmitted])
      event_store.subscribe(ExpireOrder, to: [Ordering::OrderExpired])
      event_store.subscribe(ConfirmOrder, to: [Ordering::OrderConfirmed])
      event_store.subscribe(CancelOrder, to: [Ordering::OrderCancelled])


      subscribe(
        ->(event) { broadcast_order_state_change(event.data.fetch(:order_id), 'Submitted') },
        [Ordering::OrderSubmitted]
      )
      subscribe(
        ->(event) { broadcast_order_state_change(event.data.fetch(:order_id), "Expired") },
        [Ordering::OrderExpired]
      )
      subscribe(
        ->(event) { broadcast_order_state_change(event.data.fetch(:order_id), "Paid") },
        [Ordering::OrderConfirmed]
      )
      subscribe(
        ->(event) { broadcast_order_state_change(event.data.fetch(:order_id), "Cancelled") },
        [Ordering::OrderCancelled]
      )
    end

    private

    def subscribe(handler, events)
      @event_store.subscribe(handler, to: events)
    end

    def broadcast_order_state_change(order_id, new_state)
      Turbo::StreamsChannel.broadcast_update_later_to(
        "orders_order_#{order_id}",
        target: "orders_order_#{order_id}_state",
        html: new_state)
    end
  end
end
