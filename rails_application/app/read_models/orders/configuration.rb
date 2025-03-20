module Orders
  class Order < ApplicationRecord
    self.table_name = "orders"

    has_many :order_lines,
             -> { order(id: :asc) },
             class_name: "Orders::OrderLine",
             foreign_key: :order_uid,
             primary_key: :uid

    def total_value
      order_lines.sum(:catalog_price)
    end

    def discounted_value
      order_lines.sum(:price)
    end

    def lines
      lines_query.to_a
    end

    def line(product_id, price)
      lines_query.where(product_id: product_id, price: price).first
    end

    private

    def lines_query
      order_lines
        .reorder(product_name: :asc)
        .group(:product_id, :product_name, :catalog_price, :price)
        .select("product_id, product_name, catalog_price, price, sum(quantity) as quantity, sum(price) as value")
    end
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

      event_store.subscribe(AddItemToOrder.new, to: [Pricing::PriceItemAdded])
      event_store.subscribe(RemoveItemFromOrder.new, to: [Pricing::PriceItemRemoved])
      event_store.subscribe(UpdateDiscount.new, to: [Pricing::PercentageDiscountSet, Pricing::PercentageDiscountChanged])
      event_store.subscribe(RemoveDiscount.new, to: [Pricing::PercentageDiscountRemoved])
      event_store.subscribe(ReplaceOrderLines.new, to: [Pricing::OfferItemsPricesRecalculated])
      event_store.subscribe(RegisterProduct.new, to: [ProductCatalog::ProductRegistered])
      event_store.subscribe(ChangeProductName.new, to: [ProductCatalog::ProductNamed])
      event_store.subscribe(ChangeProductPrice.new, to: [Pricing::PriceSet])
      event_store.subscribe(CreateCustomer.new, to: [Crm::CustomerRegistered])
      event_store.subscribe(AssignCustomerToOrder.new, to: [Crm::CustomerAssignedToOrder])
      event_store.subscribe(SubmitOrder.new, to: [Ordering::OrderPlaced])
      event_store.subscribe(ExpireOrder.new, to: [Ordering::OrderExpired])
      event_store.subscribe(ConfirmOrder.new, to: [Fulfillment::OrderConfirmed])
      event_store.subscribe(CancelOrder.new, to: [Fulfillment::OrderCancelled])
      event_store.subscribe(UpdateTimePromotionDiscountValue.new, to: [Pricing::PercentageDiscountSet])
      event_store.subscribe(RemoveTimePromotionDiscount.new, to: [Pricing::PercentageDiscountRemoved])

      subscribe(
        ->(event) { broadcast_order_state_change(event.data.fetch(:order_id), 'Submitted') },
        [Ordering::OrderPlaced]
      )
      subscribe(
        ->(event) { broadcast_order_state_change(event.data.fetch(:order_id), "Expired") },
        [Ordering::OrderExpired]
      )
      subscribe(
        ->(event) { broadcast_order_state_change(event.data.fetch(:order_id), "Paid") },
        [Fulfillment::OrderConfirmed]
      )
      subscribe(
        ->(event) { broadcast_order_state_change(event.data.fetch(:order_id), "Cancelled") },
        [Fulfillment::OrderCancelled]
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
