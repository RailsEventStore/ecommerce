module Orders
  class RemoveItemFromOrder
    def call(event)
      product_id = event.data.fetch(:product_id)
      order_id = event.data.fetch(:order_id)
      destroy_line(order_id , product_id, event.data.fetch(:catalog_price), event.data.fetch(:price))

      order = Order.find_by(uid: order_id)
      item = order.line(product_id, event.data.fetch(:price))
      item_value = item ? number_to_currency(item.value) : nil
      item_price = item ? number_to_currency(item.price) : nil


      broadcaster.call(order_id, product_id, "quantity", item&.quantity || 0)
      broadcaster.call(order_id, product_id, "value", item_value)
      broadcaster.call(order_id, product_id, "price", item_price)
      broadcaster.call(order_id, product_id, "remove_item_button", "") unless item

      order.order_lines.reset
      broadcaster.call(order_id, order_id, "total_value", number_to_currency(order.total_value))
      broadcaster.call(order_id, order_id, "discounted_value", number_to_currency(order.discounted_value))

      event_store.link_event_to_stream(event, "Orders$all")
    end

    private
    def destroy_line(order_uid, product_id, catalog_price, price)
      Order
        .find_by_uid(order_uid)
        .order_lines
        .where(product_id: product_id, catalog_price: catalog_price, price: price)
        .first
        .destroy!
    end

    def broadcaster
      Rails.configuration.broadcaster
    end

    def number_to_currency(number)
      ActiveSupport::NumberHelper.number_to_currency(number)
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
