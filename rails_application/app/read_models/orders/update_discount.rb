module Orders
  class UpdateDiscount < Infra::EventHandler
    def call(event)
      order = Order.find_by_uid(event.data.fetch(:order_id))
      order.percentage_discount = event.data.fetch(:amount)
      order.save!

      event_store.link_event_to_stream(event, "Orders$all")
    end
  end
end

