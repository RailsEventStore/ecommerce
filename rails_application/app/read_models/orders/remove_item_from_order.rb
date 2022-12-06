module Orders
  class RemoveItemFromOrder < Infra::EventHandler
    def call(event)
      product_id = event.data.fetch(:product_id)
      order_id = event.data.fetch(:order_id)
      item = find(order_id , product_id)
      item.quantity -= 1
      item.quantity > 0 ? item.save! : item.destroy!

      broadcaster.call(order_id, product_id, "quantity", item.quantity)
      broadcaster.call(order_id, product_id, "value", ActiveSupport::NumberHelper.number_to_currency(item.value))

      event_store.link_event_to_stream(event, "Orders$all")
    end

    private
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
  end
end
