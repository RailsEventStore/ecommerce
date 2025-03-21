module ClientOrders
  class AddItemToOrder
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::FormTagHelper

    def call(event)
      order_id = event.data.fetch(:order_id)
      product_id = event.data.fetch(:product_id)
      create_draft_order(order_id)
      item =
        find(order_id, product_id) ||
          create(order_id, product_id)
      item.product_quantity += 1
      item.save!

      broadcast_update(order_id, product_id, "product_quantity", item.product_quantity)
      broadcast_update(order_id, product_id, "value", ActiveSupport::NumberHelper.number_to_currency(item.value))
      show_remove_item_button(order_id, product_id)
    end

    private

    def show_remove_item_button(order_id, product_id)
      broadcast_update(order_id, product_id, "remove_item_button", remove_button_html(order_id, product_id))
    end

    def remove_button_html(order_id, product_id)
      button_to("Remove", remove_item_client_order_path(id: order_id, product_id: product_id), class: "hover:underline text-blue-500")
    end

    def broadcast_update(order_id, product_id, target, content)
      Turbo::StreamsChannel.broadcast_update_to(
        "client_orders_#{order_id}",
        target: "client_orders_#{product_id}_#{target}",
        html: content)
    end

    def create_draft_order(uid)
      return if Order.where(order_uid: uid).exists?
      Order.create!(order_uid: uid, state: "Draft", total_value: 0, discounted_value: 0)
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
  end
end
