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

  class TimePromotion < ApplicationRecord
    self.table_name = "client_orders_time_promotions"

    scope :current, -> { where("start_time < ? AND end_time > ?", Time.current, Time.current) }
  end

  def self.current_time_promotions_for_store(store_id)
    TimePromotion.where(store_id: store_id).current
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(OrderHandlers::ExpireOrder.new, to: [Pricing::OfferExpired])
      event_store.subscribe(OrderHandlers::CancelOrder.new, to: [Fulfillment::OrderCancelled])
      event_store.subscribe(OrderHandlers::SubmitOrder.new, to: [Fulfillment::OrderRegistered])
      event_store.subscribe(OrderHandlers::ConfirmOrder.new, to: [Fulfillment::OrderConfirmed])
      event_store.subscribe(AddItemToOrder.new, to: [Pricing::PriceItemAdded])
      event_store.subscribe(RemoveItemFromOrder.new, to: [Pricing::PriceItemRemoved])

      event_store.subscribe(CreateCustomer.new, to: [Crm::CustomerRegistered])
      event_store.subscribe(RenameCustomer.new, to: [Crm::CustomerRenamed])
      event_store.subscribe(OrderHandlers::AssignCustomerToOrder.new, to: [Crm::CustomerAssignedToOrder])

      event_store.subscribe(ProductHandlers::ChangeProductName.new, to: [ProductCatalog::ProductNamed])
      event_store.subscribe(ProductHandlers::ChangeProductPrice.new, to: [Pricing::PriceSet])
      event_store.subscribe(ProductHandlers::RegisterProduct.new, to: [ProductCatalog::ProductRegistered])
      event_store.subscribe(ProductHandlers::UpdateProductAvailability.new, to: [Inventory::AvailabilityChanged])
      event_store.subscribe(OrderHandlers::UpdateTimePromotionDiscount.new, to: [Pricing::PercentageDiscountSet])
      event_store.subscribe(OrderHandlers::RemoveTimePromotionDiscount.new, to: [Pricing::PercentageDiscountRemoved])
      event_store.subscribe(OrderHandlers::UpdateDiscount.new, to: [Pricing::PercentageDiscountSet, Pricing::PercentageDiscountChanged])
      event_store.subscribe(OrderHandlers::RemoveDiscount.new, to: [Pricing::PercentageDiscountRemoved])
      event_store.subscribe(OrderHandlers::UpdateOrderTotalValue.new, to: [Processes::TotalOrderValueUpdated])
      event_store.subscribe(OrderHandlers::UpdatePaidOrdersSummary.new, to: [Fulfillment::OrderConfirmed])

      event_store.subscribe(CreateTimePromotion.new, to: [Pricing::TimePromotionCreated])
      event_store.subscribe(AssignStoreToTimePromotion.new, to: [Stores::TimePromotionRegistered])
    end
  end
end
