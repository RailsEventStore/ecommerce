module Orders
  class RemoveDiscount
    def call(event)
      return unless event.data.fetch(:type) == Pricing::Discounts::GENERAL_DISCOUNT

      order = Order.find_by_uid(event.data.fetch(:order_id))
      order.percentage_discount = nil
      order.save!

      event_store.link_event_to_stream(event, "Orders$all")
    end

    private

    def event_store
      Rails.configuration.event_store
    end
  end
end
