module Orders
  class ResetDiscount < Infra::EventHandler
    def call(event)
      order = Order.find_by_uid(event.data.fetch(:order_id))
      order.percentage_discount = nil
      order.save!

      Rails.configuration.read_model.link_event_to_stream(event)
    end
  end
end
