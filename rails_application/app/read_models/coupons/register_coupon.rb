module Coupons
  class RegisterCoupon < Infra::EventHandler
    def call(event)
      event_data = event.data
      Coupon.create(
        uid: event_data.fetch(:coupon_id),
        name: event_data.fetch(:name),
        code: event_data.fetch(:code),
        discount: event_data.fetch(:discount)
      )
    end
  end
end
