module ClientOrders
  class RemoveItemFromOrder
    def call(event)
      item = persist_item(event)
      broadcast_to_ui(item, event)
    end

    def persist_item(event)
      item = find(event.data.fetch(:order_id), event.data.fetch(:product_id))
      item.product_quantity -= 1
      item.product_quantity > 0 ? item.save! : item.destroy!
      item
    end

    def broadcast_to_ui(item, event)
      order_id = event.data.fetch(:order_id)
      product_id = event.data.fetch(:product_id)
      broadcast_update(order_id, product_id, "product_quantity", item.product_quantity)
      broadcast_update(order_id, product_id, "value", ActiveSupport::NumberHelper.number_to_currency(item.value))
      broadcast_update(order_id, product_id, "remove_item_button", "") if zero_quantity?(item)
      event_store.link_event_to_stream(event, "ClientOrders$all")
    end

    private

    def event_store
      Rails.configuration.event_store
    end

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
