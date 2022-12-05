module Orders
  class ConfirmOrder < Infra::EventHandler
    def call(event)
      order = Order.find_by_uid(event.data.fetch(:order_id))
      order.state = "Paid"
      order.save!

      Rails.configuration.read_model.link_event_to_stream(event)
    end
  end
end