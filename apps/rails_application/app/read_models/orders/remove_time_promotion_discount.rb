module Orders
  class RemoveTimePromotionDiscount
    def call(event)
      return unless event.data.fetch(:type) == Pricing::Discounts::TIME_PROMOTION_DISCOUNT

      order = Order.find_by(uid: event.data.fetch(:order_id))

      order.time_promotion_discount_value = nil
      order.save!
    end
  end
end
