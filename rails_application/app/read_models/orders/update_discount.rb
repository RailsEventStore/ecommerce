module Orders
  class UpdateDiscount
    def call(event)
      order = Order.find_or_create_by(uid: event.data.fetch(:order_id))
      if is_newest_value?(event, order)
        order.percentage_discount = event.data.fetch(:amount)
        order.discount_updated_at = event.metadata.fetch(:timestamp)
        order.save!

        broadcaster.call(order.uid, order.uid, "percentage_discount", order.percentage_discount)
      end

      event_store.link_event_to_stream(event, "Orders$all")
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def is_newest_value?(event, order)
      order.discount_updated_at.nil? || order.discount_updated_at < event.metadata.fetch(:timestamp)
    end

    def broadcaster
      Rails.configuration.broadcaster
    end
  end
end
