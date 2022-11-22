module ClientOrders
  class RemoveItemFromOrder < Infra::EventHandler
    def call(event)
      product_id = event.data.fetch(:product_id)
      order_id = event.data.fetch(:order_id)
      item = find(order_id , product_id)
      item.product_quantity -= 1
      item.product_quantity > 0 ? item.save! : item.destroy!

      Turbo::StreamsChannel.broadcast_update_to(
        "client_orders_#{order_id}",
        target: "client_orders_#{product_id}_product_quantity",
        html: item.product_quantity)

      Turbo::StreamsChannel.broadcast_update_to(
        "client_orders_#{order_id}",
        target: "client_orders_#{product_id}_value",
        html: ActiveSupport::NumberHelper.number_to_currency(item.value))
    end

    private

    def find(order_uid, product_id)
      Order
        .find_by(order_uid: order_uid)
        .order_lines
        .where(product_id: product_id)
        .first
    end
  end
end
