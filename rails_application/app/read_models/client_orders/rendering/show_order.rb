module ClientOrders
  module Rendering
    class ShowOrder < Arbre::Component
      include Rails.application.routes.url_helpers

      def self.build(view_context, order_id)
        order = ClientOrders::Order.find_by_order_uid(order_id)
        order_lines = ClientOrders::OrderLine.where(order_uid: order_id)
        new(Arbre::Context.new(nil, view_context)).build(order, order_lines)
      end

      def build(order, order_lines, attributes = {})
        super(attributes)
        div do
          div do
            para(secondary_action_button { link_to 'Back', client_orders_path })
          end
          div class: "max-w-6xl mx-auto py-6 sm:px-6 lg:px-8" do
            header_content(order)

            div class: "mb-8" do
              state_section(order)
            end

            order_table(order_lines, order)
          end
        end
      end

      private

      def header_content(order)
        h2 do
          "Order #{order.number}"
        end
      end

      def state_section(order)
        dl do
          dt(class: "font-bold") { "State" }
          dd(class: "mb-2") { order.state }
        end
      end

      def order_table(order_lines, order)
        table class: "w-full" do
          headers_row
          tbody do
            order_lines.each do |item|
              item_row(item)
            end
          end
          footer_rows(order)
        end
      end

      def headers_row
        thead do
          tr do
            %w[Product Quantity Price Value].each do |header|
              th(class: "text-left py-2") { header }
            end
          end
        end
      end

      def item_row(item)
        tr class: "border-t" do
          td(class: "py-2") { item.product_name }
          td(class: "py-2") { item.product_quantity }
          td(class: "py-2") { number_to_currency(item.product_price) }
          td(class: "py-2 text-right") { number_to_currency(item.value) }
        end
      end

      def footer_rows(order)
        tfoot class: "border-t-4" do
          before_discounts_row(order) if order.discounted_value != order.total_value
          general_discount_row(order) if order.percentage_discount
          time_promotion_row(order) if order.time_promotion_discount
          total_row(order)
        end
      end

      def before_discounts_row(order)
        tr class: "border-t" do
          td(class: "py-2", colspan: 3) { "Before discounts" }
          td(class: "py-2 text-right", id: "before-discounts-value") { number_to_currency(order.total_value) }
        end
      end

      def general_discount_row(order)
        tr class: "border-t" do
          td(class: "py-2", colspan: 3) { "General discount" }
          td(class: "py-2 text-right") { "#{order.percentage_discount}%" }
        end
      end

      def time_promotion_row(order)
        tr class: "border-t" do
          td(class: "py-2", colspan: 3) { "Time promotion discount" }
          td(class: "py-2 text-right") { "#{order.time_promotion_discount["discount_value"]}%" }
        end
      end

      def total_row(order)
        tr class: "border-t" do
          td(class: "py-2", colspan: 3) { "Total" }
          td(class: "py-2 text-right font-bold") { number_to_currency(order.discounted_value) }
        end
      end
    end
  end
end
