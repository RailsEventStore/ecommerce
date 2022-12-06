module Orders
  class UpdateOrderTotalValue < Infra::EventHandler
    def call(event)
      order = Order.find_by_uid(event.data.fetch(:order_id))
      order.discounted_value = event.data.fetch(:discounted_amount)
      order.total_value = event.data.fetch(:total_amount)
      order.save!

      event_store.link_event_to_stream(event, "Orders$all")
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
