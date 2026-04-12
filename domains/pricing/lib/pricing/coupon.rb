require_relative 'events'

module Pricing
  class Coupon
    include AggregateRoot

    AlreadyRegistered = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

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

