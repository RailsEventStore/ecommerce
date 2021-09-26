module Orders
  class Order < ApplicationRecord
    self.table_name = "orders"

    has_many :order_lines,
             -> { order(id: :asc) },
             class_name: "Orders::OrderLine",
             foreign_key: :order_uid,
             primary_key: :uid
  end

  class OrderLine < ApplicationRecord
    self.table_name = "order_lines"

    def value
      price * quantity
    end
  end

  class Configuration
    def initialize(product_repository)
      @product_repository = product_repository
    end

    def call(event_store, command_bus)
      @cqrs = Infra::Cqrs.new(event_store, command_bus)

      subscribe(
        ->(event) { mark_as_submitted(event) },
        [Ordering::OrderSubmitted]
      )
      subscribe(
        ->(event) { change_order_state(event, "Expired") },
        [Ordering::OrderExpired]
      )
      subscribe(
        ->(event) { change_order_state(event, "Ready to ship (paid)") },
        [Ordering::OrderPaid]
      )
      subscribe(
        ->(event) { change_order_state(event, "Cancelled") },
        [Ordering::OrderCancelled]
      )
      subscribe(
        ->(event) { add_item_to_order(event) },
        [Pricing::ItemAddedToBasket]
      )
      subscribe(
        ->(event) { remove_item_from_order(event) },
        [Pricing::ItemRemovedFromBasket]
      )
      subscribe(
        ->(event) { update_discount(event) },
        [Pricing::PercentageDiscountSet]
      )
      subscribe(
        ->(event) { update_totals(event) },
        [Pricing::OrderTotalValueCalculated]
      )
    end

    private

    def subscribe(handler, events)
      link_and_handle = ->(event) do
        link_to_stream(event)
        handler.call(event)
      end
      @cqrs.subscribe(link_and_handle, events)
    end

    def mark_as_submitted(event)
      order = Order.find_or_create_by(uid: event.data.fetch(:order_id))
      order.number = event.data.fetch(:order_number)
      order.customer =
        CustomerRepository.new.find(event.data.fetch(:customer_id)).name
      order.state = "Submitted"
      order.save!
    end

    def link_to_stream(event)
      @cqrs.link_event_to_stream(event, "Orders$#{event.data.fetch(:order_id)}")
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
      product = @product_repository.find(product_id)
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

    def update_totals(event)
      with_order(event) do |order|
        order.discounted_value = event.data.fetch(:discounted_amount)
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
  end
end
