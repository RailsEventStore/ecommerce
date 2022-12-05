module Orders
  class UpdateOrderTotalValue < Infra::EventHandler
    def call(event)
      order = Order.find_by_uid(event.data.fetch(:order_id))
      order.discounted_value = event.data.fetch(:discounted_amount)
      order.total_value = event.data.fetch(:total_amount)
      order.save!

      Rails.configuration.read_model.link_event_to_stream(event)
    end
  end
end
