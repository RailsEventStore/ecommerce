module ClientOrders

  class OrdersList < Arbre::Component

    def self.build(view_context, client_id)
      new(Arbre::Context.new(nil, view_context)).build(
          Client.find_by(uid: client_id),
          Order.where(client_uid: client_id)
        )
    end

    def build(client, client_orders, attributes = {})
      super(attributes)

      div class: "max-w-6xl mx-auto py-6 sm:px-6 lg:px-8" do
        client_name_header(client)
        orders_table(client, client_orders)
        new_order_button
      end

    end

    private

    def client_name_header(client)
      h1 class: "text-3xl font-bold text-gray-900" do
        client.name
      end
    end

    def orders_table(client, client_orders)
      if client_orders.count > 0
        table class: "w-full" do
          thead do
            tr class: "border-t" do
              th class: "text-left py-2" do
                "Number"
              end
              th class: "text-left py-2" do
                "State"
              end
              th class: "text-right py-2" do
                "Price"
              end
            end
          end
          tbody do
            client_orders.each do |client_order|
              tr class: "border-t" do
                td class: "py-2" do
                  para (client_order.number || 'Not submitted')
                end
                td class: "py-2 text-left" do
                  client_order.state
                end
                td class: "py-2 text-right" do
                  number_to_currency(client_order.order.discounted_value)
                end
              end
            end
          end
        end
      else
        para do
          "No orders to display."
        end
      end
    end

    def new_order_button
      para(
        link_to(
          "New order",
          new_client_order_path,
          class: "btn btn-primary border-transparent text-white bg-blue-600 hover:bg-blue-700"))
    end
  end

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
