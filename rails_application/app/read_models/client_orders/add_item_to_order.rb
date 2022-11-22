module ClientOrders
  class AddItemToOrder < Infra::EventHandler
    def call(event)
      order_id = event.data.fetch(:order_id)
      create_draft_order(order_id)
      product_id = event.data.fetch(:product_id)
      item =
        find(order_id, product_id) ||
          create(order_id, product_id)
      item.product_quantity += 1
      item.save!

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

    def create_draft_order(uid)
      return if Order.where(order_uid: uid).exists?
      Order.create!(order_uid: uid, state: "Draft")
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
