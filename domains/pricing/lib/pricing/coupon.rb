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

    def limit_to_max_uses(max_uses)
      raise NotRegistered unless @registered

      apply CouponLimitedToMaxUses.new(
        data: {
          coupon_id: @id,
          max_uses: max_uses
        }
      )
    end

    NotRegistered = Class.new(StandardError)

    on CouponRegistered do |event|
      @registered = true
    end

    on CouponLimitedToMaxUses do |event|
    end
  end
end

