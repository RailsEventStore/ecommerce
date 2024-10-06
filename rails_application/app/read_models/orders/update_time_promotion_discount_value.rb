module Orders
  class UpdateTimePromotionDiscountValue
    def call(event)
      order = Order.find_or_create_by(uid: event.data.fetch(:order_id))

      order.time_promotion_discount_value = event.data.fetch(:amount)
      order.save!
    end
  end
end
