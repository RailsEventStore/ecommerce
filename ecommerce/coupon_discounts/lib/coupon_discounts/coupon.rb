
module CouponDiscounts
  class Coupon
    include AggregateRoot

    AlreadyRegistered = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

    def register(name, code, discount)
      raise AlreadyRegistered if @registered
      pp self.public_methods - Object.public_methods
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
