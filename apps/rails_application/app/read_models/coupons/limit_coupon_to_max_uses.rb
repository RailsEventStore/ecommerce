module Coupons
  class LimitCouponToMaxUses
    def call(event)
      Coupon.find_by!(uid: event.data.fetch(:coupon_id)).update!(max_uses: event.data.fetch(:max_uses))
    end
  end
end
