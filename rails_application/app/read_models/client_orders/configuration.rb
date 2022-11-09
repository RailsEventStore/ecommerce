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
        orders_table(client_orders)
        new_order_button
      end

    end

    private

    def client_name_header(client)
      h1 class: "text-3xl font-bold text-gray-900" do
        client.name
      end
    end

    def orders_table(client_orders)
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
        para class: "py-6" do
          "No orders to display."
        end
      end
    end

    def new_order_button
      para(
        link_to(
          "New order",
          new_client_order_path,
          class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"))
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
    has_many :order_lines,
             -> { order(id: :asc) },
             class_name: "ClientOrders::OrderLine",
             foreign_key: :order_uid,
             primary_key: :order_uid
    # has_many :payment_intents, class_name: "ClientOrders::PaymentIntent",
    #          foreign_key: :order_uid,
    #          primary_key: :order_uid
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

  # class PaymentIntent < ApplicationRecord
  #   self.table_name = "client_payment_intents"
  #   belongs_to :order, class_name: "Orders::Order", foreign_key: :order_uid, primary_key: :uid
  # end

  class Configuration
    def call(event_store)
      @event_store = event_store

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

      subscribe_and_link_to_stream(
        ->(event) { add_item_to_order(event) },
        [Ordering::ItemAddedToBasket]
      )

      subscribe_and_link_to_stream(
        ->(event) { remove_item_from_order(event) },
        [Ordering::ItemRemovedFromBasket]
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

    def link_to_stream(event)
      @event_store.link_event_to_stream(event, "ClientOrders$all")
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

    def add_item_to_order(event)
      order_id = event.data.fetch(:order_id)
      create_draft_order(order_id)
      item =
        find(order_id, event.data.fetch(:product_id)) ||
          create(order_id, event.data.fetch(:product_id))
      item.product_quantity += 1
      item.save!
    end

    def create_draft_order(uid)
      return if Order.where(order_uid: uid).exists?
      Order.create!(order_uid: uid, state: "Draft")
    end

    def find(order_uid, product_id)
      Order
        .find_by(order_uid: order_uid)
        .order_lines
        .where(product_id: product_id)
        .first
    end

    def create(order_uid, product_id)
      product = Product.find_by_uid(product_id)
      Order
        .find_by(order_uid: order_uid)
        .order_lines
        .create(
          product_id: product_id,
          product_name: product.name,
          product_price: product.price,
          product_quantity: 0
        )
    end

    def remove_item_from_order(event)
      item = find(event.data.fetch(:order_id), event.data.fetch(:product_id))
      item.product_quantity -= 1
      item.product_quantity > 0 ? item.save! : item.destroy!
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
  end
end
