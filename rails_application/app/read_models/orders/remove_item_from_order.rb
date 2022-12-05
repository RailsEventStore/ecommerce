module Orders
  class RemoveItemFromOrder < Infra::EventHandler
    def call(event)
      product_id = event.data.fetch(:product_id)
      order_id = event.data.fetch(:order_id)
      item = find(order_id , product_id)
      item.quantity -= 1
      item.quantity > 0 ? item.save! : item.destroy!

      read_model.broadcast_update(order_id, product_id, "quantity", item.quantity)
      read_model.broadcast_update(order_id, product_id, "value", ActiveSupport::NumberHelper.number_to_currency(item.value))

      link_event_to_stream(event)
    end

    private
    def find(order_uid, product_id)
      Order
        .find_by_uid(order_uid)
        .order_lines
        .where(product_id: product_id)
        .first
    end

    def read_model
      Rails.configuration.read_model
    end
  end
end
