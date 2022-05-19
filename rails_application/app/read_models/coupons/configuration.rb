module Coupons
  class Coupon < ApplicationRecord
    self.table_name = "coupons"
  end

  class Configuration
    def call(cqrs)
      cqrs.subscribe(
        -> (event) { register_coupon(event) },
        [CouponDiscounts::CouponRegistered]
      )
    end

    private

    def register_coupon(event)
      event_data = event.data
      Coupon.create(
        uid: event_data.fetch(:coupon_id),
        name: event_data.fetch(:name),
        code: event_data.fetch(:code),
        discount: event_data.fetch(:discount)
      )
    end

    def find(coupon_id)
      Coupon.find_by(uid: coupon_id)
    end
  end
end
