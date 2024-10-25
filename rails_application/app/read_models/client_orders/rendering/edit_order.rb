module ClientOrders
  module Rendering
    class EditOrder < Arbre::Component
      include Rails.application.routes.url_helpers
      include ActionView::Helpers::FormTagHelper
      include ActionView::Helpers::UrlHelper

      def self.build(view_context, order_id)
        order = ClientOrders::Order.find_or_initialize_by(order_uid: order_id) do |order|
          order.total_value = 0
          order.discounted_value = 0
        end
        order_lines = ClientOrders::OrderLine.where(order_uid: order_id)
        products = ClientOrders::Product.all
        time_promotions = TimePromotions::TimePromotion.current
        new(Arbre::Context.new(nil, view_context)).build(order, order_lines, products, time_promotions)
      end

      def build(order, order_lines, products, time_promotions, attributes = {})
        super(attributes)
        div do
          products_table(order, products, order_lines, time_promotions)
          coupon_form(order)
          submit_form(order)
        end
      end

      private

      def products_table(order, products, order_lines, time_promotions)
        table class: "w-full" do
          headers_row
          products_rows(order, products, order_lines)
          footer_rows(order, time_promotions)
        end
      end

      def headers_row
        thead do
          tr do
            th(class: "text-left py-2") { "Product" }
            th(class: "text-left py-2") { "" }
            th(class: "text-left py-2") { "Quantity" }
            th(class: "text-left py-2") { "Price" }
            th(class: "text-left py-2", colspan: 3) { "Value" }
          end
        end
      end

      def products_rows(order, products, order_lines)
        tbody do
          text_node turbo_stream_from "client_orders_#{order.order_uid}"
          products.each do |product|
            product_row(order, product, order_lines)
          end
        end
      end

      def product_row(order, product, order_lines)
        order_line = order_lines&.find { |order_line| order_line.product_id == product.uid }
        tr class: "border-b" do
          td(class: "py-2") { product.name }
          td(class: "py-2") { out_of_stock_badge unless product.available? }
          td(class: "py-2", id: "client_orders_#{product.uid}_product_quantity") { order_line.try(&:product_quantity) || 0 }
          td(class: "py-2") { number_to_currency(product.price) }
          td(class: "py-2", id: "client_orders_#{product.uid}_value") { number_to_currency(order_line.try(&:value)) || "$0.00" }
          td(class: "py-2 text-right") { add_item_button(order.order_uid, product.uid) }
          td(class: "py-2 text-right", id: "client_orders_#{product.uid}_remove_item_button") { remove_item_button(order, product.uid) if order_line }
        end
      end

      def footer_rows(order, time_promotions)
        tfoot class:"border-t-4" do
          before_discounts_row(order) if order.percentage_discount || time_promotions.any?
          coupon_discount_row(order) if order.percentage_discount
          time_promotions_rows(time_promotions)
          total_row(order)
        end
      end

      def out_of_stock_badge
        span "out of stock", class: "rounded-lg bg-yellow-400 text-yellow-900 px-2 py-0.5"
      end

      def add_item_button(order_id, product_id)
        button_to "Add", add_item_client_order_path(id: order_id, product_id: product_id), class: "hover:underline text-blue-500"
      end

      def remove_item_button(order, product_id)
        button_to "Remove", remove_item_client_order_path(id: order.order_uid, product_id: product_id), class: "hover:underline text-blue-500"
      end

      def before_discounts_row(order)
        tr(class: "border-t") do
          td(class: "py-2", colspan: 4) { "Before discounts" }
          td(class: "py-2", id: "client_orders_#{order.order_uid}_total_value") { number_to_currency(order.total_value) }
        end
      end

      def coupon_discount_row(order)
        tr(class: "border-t") do
          td(class: "py-2", colspan: 4) { "Coupon discount" }
          td(class: "py-2", id: "client_orders_#{order.order_uid}_percentage_discount") { "#{order.percentage_discount}%" }
        end
      end

      def time_promotions_rows(time_promotions)
        time_promotions.each do |time_promotion|
          tr(class: "border-t") do
            td(class: "py-2", colspan: 4) { "Promotion: #{time_promotion.label} (if you buy before #{time_promotion.end_time})"}
            td(class: "py-2") { "#{time_promotion.discount}%" }
          end
        end
      end

      def total_row(order)
        tr(class: "border-t") do
          td(class: "py-2", colspan: 4) { "Total" }
          td(class: "py-2 font-bold", id: "client_orders_#{order.order_uid}_discounted_value") { number_to_currency(order.discounted_value) }
        end
      end

      def coupon_form(order)
        form(action: use_coupon_client_order_path(id: order.order_uid), method: :post, class: "inline-flex gap-4 mt-8") do
          input(
            id: "coupon_code",
            type: :text,
            name: :coupon_code,
            class: "focus:ring-blue-500 focus:border-blue-500 block shadow-sm sm:text-sm border-gray-300 rounded-md",
            "data-turbo-permanent": true
          )
          input(type: :submit, value: "Use Coupon", class: "px-4 py-2 border rounded-md shadow-sm text-sm font-medium border-gray-300 text-gray-700 bg-white hover:bg-gray-50")
        end
      end

      def submit_form(order)
        form(id: "form", action: client_orders_path, method: :post) do
          input(type: :hidden, name: :order_id, value: order.order_uid)
          div(class: "mt-8") do
            input type: :submit, value: "Create Order", class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
          end
        end
      end
    end
  end
end
