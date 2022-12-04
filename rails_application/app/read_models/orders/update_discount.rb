module Orders
  class UpdateDiscount < ReadModel
    def call(event)
      order = Order.find_by_uid(event.data.fetch(:order_id))
      order.percentage_discount = event.data.fetch(:amount)
      order.save!

      link_event_to_stream(event)
    end
  end
end

