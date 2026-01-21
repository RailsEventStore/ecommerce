require_relative "events"
require_relative "coupon_discount"

module Pricing
  class Coupon
    include AggregateRoot

    AlreadyRegistered = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

    def register(name, code, discount_raw)
      raise AlreadyRegistered if @registered

      discount = discount_raw.is_a?(CouponDiscount) ? discount_raw : CouponDiscount.parse(discount_raw)

      apply CouponRegistered.new(
        data: {
          coupon_id: @id,
          name: name,
          code: code,
          discount: discount.to_d
        }
      )
    end

    on CouponRegistered do |_event|
      @registered = true
    end
  end
end
