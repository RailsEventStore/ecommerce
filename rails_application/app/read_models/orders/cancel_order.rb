module Orders
  class CancelOrder < Infra::EventHandler
    def call(event)
      order = Order.find_by_uid(event.data.fetch(:order_id))
      order.state = "Cancelled"
      order.save!

      Rails.configuration.read_model.link_event_to_stream(event)
    end
  end
end