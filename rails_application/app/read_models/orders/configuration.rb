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

    def call(cqrs)
      @cqrs = cqrs

      subscribe_and_link_to_stream(
        ->(event) { mark_as_submitted(event) },
        [Ordering::OrderSubmitted]
      )
      subscribe_and_link_to_stream(
        ->(event) { change_order_state(event, "Expired") },
        [Ordering::OrderExpired]
      )
      subscribe_and_link_to_stream(
        ->(event) { change_order_state(event, "Paid") },
        [Ordering::OrderConfirmed]
      )
      subscribe_and_link_to_stream(
        ->(event) { change_order_state(event, "Cancelled") },
        [Ordering::OrderCancelled]
      )
      subscribe_and_link_to_stream(
        ->(event) { add_item_to_order(event) },
        [Ordering::ItemAddedToBasket]
      )
      subscribe_and_link_to_stream(
        ->(event) { remove_item_from_order(event) },
        [Ordering::ItemRemovedFromBasket]
      )
      subscribe_and_link_to_stream(
        ->(event) { update_discount(event) },
        [Pricing::PercentageDiscountSet, Pricing::PercentageDiscountChanged]
      )
      subscribe_and_link_to_stream(
        ->(event) { reset_discount(event) },
        [Pricing::PercentageDiscountReset]
      )
      subscribe_and_link_to_stream(
        ->(event) { update_totals(event) },
        [Pricing::OrderTotalValueCalculated]
      )

      subscribe_and_link_to_stream(
        -> (event) { create_product(event) },
        [ProductCatalog::ProductRegistered]
      )

      subscribe_and_link_to_stream(
        -> (event) { name_product(event) },
        [ProductCatalog::ProductNamed]
      )

      subscribe_and_link_to_stream(
        -> (event) { change_product_price(event) },
        [Pricing::PriceSet]
      )

      subscribe_and_link_to_stream(
        -> (event) { create_customer(event) },
        [Crm::CustomerRegistered]
      )

      subscribe_and_link_to_stream(
        -> (event) { assign_customer(event, event.data.fetch(:customer_id)) },
        [Crm::CustomerAssignedToOrder]
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
      @cqrs.subscribe(handler, events)
    end

    def mark_as_submitted(event)
      order = Order.find_or_create_by(uid: event.data.fetch(:order_id))
      order.number = event.data.fetch(:order_number)
      order.state = "Submitted"
      order.save!
    end

    def link_to_stream(event)
      @cqrs.link_event_to_stream(event, "Orders$all")
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
  end
end
