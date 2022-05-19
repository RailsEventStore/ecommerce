
module CouponDiscounts
  class Coupon
    include AggregateRoot

    AlreadyRegistered = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

    # TODO: do not allow for duplicates name and value coupons
    def register(name, code, discount)
      raise AlreadyRegistered if @registered

      apply CouponRegistered.new(
        data: {
          coupon_id: @id,
          name: name,
          code: code,
          discount: discount
        }
      )
    end

    on CouponRegistered do |event|
      @registered = true
    end
  end
end
