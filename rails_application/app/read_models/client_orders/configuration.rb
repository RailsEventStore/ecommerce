require_relative 'rendering/orders_list'
require_relative 'rendering/show_order'
require_relative 'rendering/edit_order'

require_relative 'product_handlers'
require_relative 'order_handlers'

module ClientOrders

  class Client < ApplicationRecord
    self.table_name = "clients"

    has_many :client_orders,
             -> { client(id: :asc) },
             class_name: "ClientOrders::Order",
             foreign_key: :client_uid,
             primary_key: :uid
  end

  class Order < ApplicationRecord
    self.table_name = "client_orders"

    has_many :order_lines,
             -> { order(id: :asc) },
             class_name: "ClientOrders::OrderLine",
             foreign_key: :order_uid,
             primary_key: :order_uid
  end

  class OrderLine < ApplicationRecord
    self.table_name = "client_order_lines"

    def value
      product_price * product_quantity
    end
  end

  class Product < ApplicationRecord
    self.table_name = "client_order_products"
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(OrderHandlers::ExpireOrder, to: [Ordering::OrderExpired])
      event_store.subscribe(OrderHandlers::CancelOrder, to: [Fulfillment::OrderCancelled])
      event_store.subscribe(OrderHandlers::SubmitOrder, to: [Ordering::OrderPlaced])
      event_store.subscribe(OrderHandlers::ConfirmOrder, to: [Fulfillment::OrderConfirmed])
      event_store.subscribe(AddItemToOrder, to: [Ordering::ItemAddedToBasket])
      event_store.subscribe(RemoveItemFromOrder, to: [Ordering::ItemRemovedFromBasket])

      event_store.subscribe(CreateCustomer.new, to: [Crm::CustomerRegistered])
      event_store.subscribe(OrderHandlers::AssignCustomerToOrder, to: [Crm::CustomerAssignedToOrder])

      event_store.subscribe(ProductHandlers::ChangeProductName, to: [ProductCatalog::ProductNamed])
      event_store.subscribe(ProductHandlers::ChangeProductPrice, to: [Pricing::PriceSet])
      event_store.subscribe(ProductHandlers::RegisterProduct, to: [ProductCatalog::ProductRegistered])
      event_store.subscribe(ProductHandlers::UpdateProductAvailability, to: [Inventory::AvailabilityChanged])
      event_store.subscribe(OrderHandlers::UpdateDiscount, to: [Pricing::PercentageDiscountSet, Pricing::PercentageDiscountChanged])
      event_store.subscribe(OrderHandlers::ResetDiscount, to: [Pricing::PercentageDiscountReset])
      event_store.subscribe(OrderHandlers::UpdateOrderTotalValue, to: [Pricing::OrderTotalValueCalculated])
      event_store.subscribe(OrderHandlers::UpdatePaidOrdersSummary, to: [Fulfillment::OrderConfirmed])
    end
  end
end
