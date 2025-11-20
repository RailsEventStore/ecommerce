module Orders
  class Order < ApplicationRecord
    self.table_name = "orders"

    has_many :order_lines,
             -> { order(id: :asc) },
             class_name: "Orders::OrderLine",
             foreign_key: :order_uid,
             primary_key: :uid
  end

  private_constant :Order

  class Product < ApplicationRecord
    self.table_name = "orders_products"
  end

  private_constant :Product

  class Customer < ApplicationRecord
    self.table_name = "orders_customers"
  end

  private_constant :Customer

  class OrderLine < ApplicationRecord
    self.table_name = "order_lines"

    def value
      price * quantity
    end
  end

  private_constant :OrderLine

  def self.order_lines_for(order_uid)
    OrderLine.where(order_uid: order_uid)
  end

  def self.find_order_line(order_uid:, product_id:)
    OrderLine.where(order_uid: order_uid, product_id: product_id).first
  end

  def self.find_product(product_id)
    Product.find_by_uid!(product_id)
  end

  def self.all_orders
    Order.all
  end

  def self.paginated_orders(page)
    Order.order("id DESC").page(page).per(10)
  end

  def self.find_order(uid)
    Order.find_by_uid(uid)
  end

  def self.find_order!(uid)
    Order.find_by_uid!(uid)
  end

  def self.find_or_create_order(uid)
    Order.find_or_create_by!(uid: uid)
  end

  def self.draft_orders
    Order.where(state: "Draft")
  end

  class Configuration

    def call(event_store)
      Rails.configuration.broadcaster = Orders::Broadcaster.new

      event_store.subscribe(DraftOrder.new, to: [Pricing::OfferDrafted])
      event_store.subscribe(AssignStoreToOrder.new, to: [Stores::OfferRegistered])
      event_store.subscribe(AddItemToOrder.new, to: [Pricing::PriceItemAdded])
      event_store.subscribe(RemoveItemFromOrder.new, to: [Pricing::PriceItemRemoved])
      event_store.subscribe(UpdateDiscount.new, to: [Pricing::PercentageDiscountSet, Pricing::PercentageDiscountChanged])
      event_store.subscribe(RemoveDiscount.new, to: [Pricing::PercentageDiscountRemoved])
      event_store.subscribe(UpdateOrderTotalValue.new, to: [Processes::TotalOrderValueUpdated])
      event_store.subscribe(RegisterProduct.new, to: [ProductCatalog::ProductRegistered])
      event_store.subscribe(ChangeProductName.new, to: [ProductCatalog::ProductNamed])
      event_store.subscribe(ChangeProductPrice.new, to: [Pricing::PriceSet])
      event_store.subscribe(CreateCustomer.new, to: [Crm::CustomerRegistered])
      event_store.subscribe(AssignCustomerToOrder.new, to: [Crm::CustomerAssignedToOrder])
      event_store.subscribe(SubmitOrder.new, to: [Fulfillment::OrderRegistered])
      event_store.subscribe(ExpireOrder.new, to: [Pricing::OfferExpired])
      event_store.subscribe(ConfirmOrder.new, to: [Fulfillment::OrderConfirmed])
      event_store.subscribe(CancelOrder.new, to: [Fulfillment::OrderCancelled])
      event_store.subscribe(UpdateTimePromotionDiscountValue.new, to: [Pricing::PercentageDiscountSet])
      event_store.subscribe(RemoveTimePromotionDiscount.new, to: [Pricing::PercentageDiscountRemoved])

      event_store.subscribe(
        ->(event) { broadcast_order_state_change(event.data.fetch(:order_id), 'Submitted') },
        to: [Fulfillment::OrderRegistered]
      )
      event_store.subscribe(
        ->(event) { broadcast_order_state_change(event.data.fetch(:order_id), "Expired") },
        to: [Pricing::OfferExpired]
      )
      event_store.subscribe(
        ->(event) { broadcast_order_state_change(event.data.fetch(:order_id), "Paid") },
        to: [Fulfillment::OrderConfirmed]
      )
      event_store.subscribe(
        ->(event) { broadcast_order_state_change(event.data.fetch(:order_id), "Cancelled") },
        to: [Fulfillment::OrderCancelled]
      )
    end

    private

    def broadcast_order_state_change(order_id, new_state)
      Turbo::StreamsChannel.broadcast_update_later_to(
        "orders_order_#{order_id}",
        target: "orders_order_#{order_id}_state",
        html: new_state)
    end
  end
end
