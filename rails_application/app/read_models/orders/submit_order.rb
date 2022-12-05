module Orders
  class SubmitOrder < Infra::EventHandler
    def call(event)
      order = Order.find_or_create_by(uid: event.data.fetch(:order_id))
      order.number = event.data.fetch(:order_number)
      order.state = "Submitted"
      order.save!

      Rails.configuration.read_model.link_event_to_stream(event)
    end
  end
end