module Orders
  class RemoveItemFromOrder
    def call(event)
      product_id = event.data.fetch(:product_id)
      order_id = event.data.fetch(:order_id)
      item = find(order_id , product_id)
      item.quantity -= 1
      item.quantity > 0 ? item.save! : item.destroy!

      broadcast_to_ui(item, order_id, product_id)
      event_store.link_event_to_stream(event, "Orders$all")
    end

    private

    def broadcast_to_ui(item, order_id, product_id)
      broadcaster.call(order_id, product_id, "quantity", item.quantity)
      broadcaster.call(order_id, product_id, "value", ActiveSupport::NumberHelper.number_to_currency(item.value))
      broadcaster.call(order_id, product_id, "remove_item_button", "") if item.quantity.zero?
    end

    def find(order_uid, product_id)
      Order
        .find_by_uid(order_uid)
        .order_lines
        .where(product_id: product_id)
        .first
    end

    def broadcaster
      Rails.configuration.broadcaster
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
