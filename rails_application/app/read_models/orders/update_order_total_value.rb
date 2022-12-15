module Orders
  class UpdateOrderTotalValue < Infra::EventHandler
    def call(event)
      order_id = event.data.fetch(:order_id)
      ApplicationRecord.with_advisory_lock(order_id) do
        order = Order.find_or_create_by(uid: order_id)
        order.discounted_value = event.data.fetch(:discounted_amount)
        order.total_value = event.data.fetch(:total_amount)
        order.save!

        broadcaster.call(order.uid, order.uid, "total_value", number_to_currency(order.total_value))
        broadcaster.call(order.uid, order.uid, "discounted_value", number_to_currency(order.discounted_value))
      end

      event_store.link_event_to_stream(event, "Orders$all")
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
