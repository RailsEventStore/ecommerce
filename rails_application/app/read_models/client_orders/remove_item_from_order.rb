module ClientOrders
  class RemoveItemFromOrder < Infra::EventHandler
    def call(event)
      item = find(event.data.fetch(:order_id), event.data.fetch(:product_id))
      item.product_quantity -= 1
      item.product_quantity > 0 ? item.save! : item.destroy!
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
