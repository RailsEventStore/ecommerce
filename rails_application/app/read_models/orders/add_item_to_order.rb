module Orders
  class AddItemToOrder < Infra::EventHandler
    def call(event)
      order_id = event.data.fetch(:order_id)
      ApplicationRecord.with_advisory_lock(order_id) do
        Order.find_or_create_by!(uid: order_id) { |order| order.state = "Draft" }
        product_id = event.data.fetch(:product_id)
        item =
          find(order_id, product_id) ||
            create(order_id, product_id)
        item.quantity += 1
        item.save!

        broadcaster.call(order_id, product_id, "quantity", item.quantity)
        broadcaster.call(order_id, product_id, "value", ActiveSupport::NumberHelper.number_to_currency(item.value))
      end

      event_store.link_event_to_stream(event, "Orders$all")
    end

    private

    def broadcaster
      Rails.configuration.broadcaster
    end

    def find(order_uid, product_id)
      Order
        .find_by_uid(order_uid)
        .order_lines
        .where(product_id: product_id)
        .first
    end

    def create(order_uid, product_id)
      product = Product.find_by_uid(product_id)
      Order
        .find_by(uid: order_uid)
        .order_lines
        .create(
          product_id: product_id,
          product_name: product.name,
          price: product.price,
          quantity: 0
        )
    end
  end
end
