module Orders
  class AddItemToOrder
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::FormTagHelper

    def call(event)
      order_id = event.data.fetch(:order_id)
      order = Order.find_or_create_by!(uid: order_id) { |order| order.state = "Draft" }
      product_id = event.data.fetch(:product_id)
      create(order_id, event.data.fetch(:product_id), event.data.fetch(:catalog_price), event.data.fetch(:price))

      item = order.line(product_id, event.data.fetch(:price))
      broadcaster.call(order_id, product_id, "quantity", item.quantity)
      broadcaster.call(order_id, product_id, "price", number_to_currency(item.price))
      broadcaster.call(order_id, product_id, "value", number_to_currency(item.value))
      broadcaster.call(order_id, product_id, "remove_item_button", button_to("Remove", remove_item_order_path(id: order_id, product_id: product_id), class: "hover:underline text-blue-500"))

      order.order_lines.reset
      broadcaster.call(order.uid, order.uid, "total_value", number_to_currency(order.total_value))
      broadcaster.call(order.uid, order.uid, "discounted_value", number_to_currency(order.discounted_value))

      event_store.link_event_to_stream(event, "Orders$all")
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def broadcaster
      Rails.configuration.broadcaster
    end

    def number_to_currency(number)
      ActiveSupport::NumberHelper.number_to_currency(number)
    end

    def find(order_uid, product_id)
      Order
        .find_by_uid(order_uid)
        .order_lines
        .where(product_id: product_id)
        .first
    end

    def create(order_uid, product_id, catalog_price, price)
      product = Product.find_by_uid(product_id)
      Order
        .find_by(uid: order_uid)
        .order_lines
        .create!(
          product_id: product_id,
          product_name: product.name,
          price: price,
          catalog_price: catalog_price,
          quantity: 1
        )
    end
  end
end
