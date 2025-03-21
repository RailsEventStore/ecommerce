module Orders
  class ReplaceOrderLines
    def call(event)
      order = Order.find_by(uid: event.data.fetch(:order_id))
      order.order_lines.destroy_all

      product_ids = event.data.fetch(:order_items).map { |line| line.fetch(:product_id) }
      product_names = Product.where(uid: product_ids).pluck(:uid, :name).to_h
      OrderLine.upsert_all(
        event.data.fetch(:order_items).map do |item|
          {
            order_uid: order.uid,
            product_id: product_id = item.fetch(:product_id),
            product_name: product_names.fetch(product_id),
            price: item.fetch(:price),
            catalog_price: item.fetch(:catalog_price),
            quantity: 1,
          }
        end
      )

      order.reload
      broadcaster.call(order.uid, order.uid, "total_value", number_to_currency(order.total_value))
      broadcaster.call(order.uid, order.uid, "discounted_value", number_to_currency(order.discounted_value))
    end

    private

    def broadcaster
      Rails.configuration.broadcaster
    end

    def number_to_currency(number)
      ActiveSupport::NumberHelper.number_to_currency(number)
    end
  end
end
