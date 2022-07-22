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

    belongs_to :order, class_name: "Orders::Order", foreign_key: :order_uid, primary_key: :uid
  end

  class Configuration
    def call(cqrs)
      @cqrs = cqrs

      subscribe_and_link_to_stream(
        ->(event) { create_client(event) },
        [Crm::CustomerRegistered]
      )

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

    def link_to_stream(event)
      @cqrs.link_event_to_stream(event, "ClientOrders$all")
    end

    def create_client(event)
      Client.create(
        uid: event.data.fetch(:customer_id),
        name: event.data.fetch(:name)
      )
    end

    def mark_as_submitted(event)
      order = Order.find_or_create_by(order_uid: event.data.fetch(:order_id))
      order.number = event.data.fetch(:order_number)
      order.state = "Submitted"
      order.save!
    end

    def change_order_state(event, new_state)
      with_order(event) { |order| order.state = new_state }
    end

    def with_order(event)
      order = Order.find_by(order_uid: event.data.fetch(:order_id))
      unless order.nil?
        yield(order)
        order.save!
      end
    end

    def assign_customer(event, customer_id)
      with_order(event) { |order| order.client_uid = customer_id }
    end
  end
end
