module Coupons
  class Coupon < ApplicationRecord
    self.table_name = "coupons"
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(RegisterCoupon, to: [Pricing::CouponRegistered])
    end
  end
end
