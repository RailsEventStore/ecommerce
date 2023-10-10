module ClientOrders

  class OrdersList < Arbre::Component
    include Rails.application.routes.url_helpers

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
      return no_orders_message if client_orders.empty?
      orders_table_content(client, client_orders)
    end

    def orders_table_content(client, client_orders)
      table class: "w-full", id: "orders" do
        headers_row
        tbody do
          orders_rows(client_orders)
          summary_row(client)
        end
      end
    end

    def no_orders_message
      para class: "py-6" do
        "No orders to display."
      end
    end

    def summary_row(client)
      tr class: "border-t font-bold" do
        td colspan: 2, class: "py-2" do
          para "Total paid orders"
        end
        td class: "py-2 text-right border-t" do
          number_to_currency(client.paid_orders_summary)
        end
      end
    end

    def orders_rows(client_orders)
      client_orders.each do |client_order|
        tr class: "border-t" do
          td class: "py-2" do
            para(order_link_with_order_number(client_order) || 'Not submitted')
          end
          td class: "py-2 text-left" do
            client_order.state
          end
          td class: "py-2 text-right" do
            number_to_currency(client_order.discounted_value)
          end
        end
      end
    end

    def headers_row
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
    end

    def new_order_button
      para(
        link_to(
          "New order",
          new_client_order_path,
          class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"))
    end

    def order_link_with_order_number(order)
      link_to(
        order.number,
        client_order_path(order.order_uid),
        class: "text-blue-500 hover:text-blue-700"
      )
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

  class Configuration
    def call(event_store)
      event_store.subscribe(ExpireOrder, to: [Ordering::OrderExpired])
      event_store.subscribe(CancelOrder, to: [Ordering::OrderCancelled])
      event_store.subscribe(SubmitOrder, to: [Ordering::OrderSubmitted])
      event_store.subscribe(ConfirmOrder, to: [Ordering::OrderConfirmed])
      event_store.subscribe(AddItemToOrder, to: [Ordering::ItemAddedToBasket])
      event_store.subscribe(RemoveItemFromOrder, to: [Ordering::ItemRemovedFromBasket])

      event_store.subscribe(CreateCustomer.new, to: [Crm::CustomerRegistered])
      event_store.subscribe(AssignCustomerToOrder, to: [Crm::CustomerAssignedToOrder])

      event_store.subscribe(ChangeProductName, to: [ProductCatalog::ProductNamed])
      event_store.subscribe(ChangeProductPrice, to: [Pricing::PriceSet])
      event_store.subscribe(RegisterProduct, to: [ProductCatalog::ProductRegistered])
      event_store.subscribe(UpdateDiscount, to: [Pricing::PercentageDiscountSet, Pricing::PercentageDiscountChanged])
      event_store.subscribe(ResetDiscount, to: [Pricing::PercentageDiscountReset])
      event_store.subscribe(UpdateOrderTotalValue, to: [Pricing::OrderTotalValueCalculated])
      event_store.subscribe(UpdatePaidOrdersSummary, to: [Ordering::OrderConfirmed])
    end
  end
end
