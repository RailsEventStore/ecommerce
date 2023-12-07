module ClientOrders
  class RemoveItemFromOrder < Infra::EventHandler
    def call(event)
      product_id = event.data.fetch(:product_id)
      order_id = event.data.fetch(:order_id)
      item = find(order_id , product_id)
      item.product_quantity -= 1
      item.product_quantity > 0 ? item.save! : item.destroy!

      broadcast_update(order_id, product_id, "product_quantity", item.product_quantity)
      broadcast_update(order_id, product_id, "value", ActiveSupport::NumberHelper.number_to_currency(item.value))
      broadcast_update(order_id, product_id, "remove_item_button", "") if zero_quantity?(item)

      event_store.link_event_to_stream(event, "ClientOrders$all")
    end

    private

    def zero_quantity?(item)
      item.nil? || item.product_quantity.zero?
    end

    def broadcast_update(order_id, product_id, target, content)
      Turbo::StreamsChannel.broadcast_update_to(
        "client_orders_#{order_id}",
        target: "client_orders_#{product_id}_#{target}",
        html: content)
    end

    def find(order_uid, product_id)
      Order
        .find_by(order_uid: order_uid)
        .order_lines
        .where(product_id: product_id)
        .first
    end
  end
end
