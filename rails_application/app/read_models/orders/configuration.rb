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

    def subscribe_and_link_to_stream(handler, events)
      link_and_handle = ->(event) do
        link_to_stream(event)
        handler.call(event)
      end
      subscribe(link_and_handle, events)
    end

    def subscribe(handler, events)
      @event_store.subscribe(handler, to: events)
    end

    def mark_as_submitted(event)
      order = Order.find_or_create_by(uid: event.data.fetch(:order_id))
      order.number = event.data.fetch(:order_number)
      order.state = "Submitted"
      order.save!
    end

    def link_to_stream(event)
      @event_store.link_event_to_stream(event, "Orders$all")
    end

    def add_item_to_order(event)
      order_id = event.data.fetch(:order_id)
      create_draft_order(order_id)
      item =
        find(order_id, event.data.fetch(:product_id)) ||
          create(order_id, event.data.fetch(:product_id))
      item.quantity += 1
      item.save!
    end

    def create_draft_order(uid)
      return if Order.where(uid: uid).exists?
      Order.create!(uid: uid, state: "Draft")
    end

    def find(order_uid, product_id)
      Order
        .find_by_uid(order_uid)
        .order_lines
        .where(product_id: product_id)
        .first
    end

    def create(order_uid, product_id)
      product = Product.find_by_uid(product_id)
      Order
        .find_by(uid: order_uid)
        .order_lines
        .create(
          product_id: product_id,
          product_name: product.name,
          price: product.price,
          quantity: 0
        )
    end

    def remove_item_from_order(event)
      item = find(event.data.fetch(:order_id), event.data.fetch(:product_id))
      item.quantity -= 1
      item.quantity > 0 ? item.save! : item.destroy!
    end

    def update_discount(event)
      with_order(event) do |order|
        order.percentage_discount = event.data.fetch(:amount)
      end
    end

    def reset_discount(event)
      with_order(event) do |order|
        order.percentage_discount = nil
      end
    end

    def update_totals(event)
      with_order(event) do |order|
        order.discounted_value = event.data.fetch(:discounted_amount)
        order.total_value = event.data.fetch(:total_amount)
      end
    end

    def change_order_state(event, new_state)
      with_order(event) { |order| order.state = new_state }
    end

    def with_order(event)
      Order
        .find_by_uid(event.data.fetch(:order_id))
        .tap do |order|
          yield(order)
          order.save!
        end
    end

    def create_product(event)
      Product.create(uid: event.data.fetch(:product_id))
    end

    def name_product(event)
      Product.find_by_uid(event.data.fetch(:product_id)).update(
        name: event.data.fetch(:name)
      )
    end

    def change_product_price(event)
      Product.find_by_uid(event.data.fetch(:product_id)).update(price: event.data.fetch(:price))
    end

    def create_customer(event)
      Customer.create(
        uid:  event.data.fetch(:customer_id),
        name: event.data.fetch(:name)
      )
    end

    def assign_customer(event, customer_id)
      create_draft_order(event.data.fetch(:order_id))
      with_order(event) { |order| order.customer = Customer.find_by_uid(customer_id).name }
    end

    def broadcast_order_state_change(order_id, new_state)
      Turbo::StreamsChannel.broadcast_update_later_to(
        "orders_order_#{order_id}",
        target: "orders_order_#{order_id}_state",
        html: new_state)
    end
  end
end
