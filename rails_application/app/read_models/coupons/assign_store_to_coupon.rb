module Coupons
  class AssignStoreToCoupon
    def call(event)
      Coupon.find_by!(uid: event.data.fetch(:coupon_id)).update!(store_id: event.data.fetch(:store_id))
    end
  end
end
