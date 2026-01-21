# frozen_string_literal: true

require "bigdecimal"
module Pricing
  class CouponDiscount
    UnacceptableRange = Class.new(StandardError)
    Unparseable = Class.new(StandardError)

    def self.parse(raw)
      new(raw)
    rescue ArgumentError
      raise Unparseable, "Discount must be a number"
    end

    attr_reader :value

    def initialize(raw)
      @value = BigDecimal(raw.to_s).freeze

      raise UnacceptableRange, "Discount must be greater than 0" if @value <= 0
      raise UnacceptableRange, "Discount must be less than or equal to 100" if @value > 100
    end

    def to_d
      value
    end

    def to_s
      value.to_s("F")
    end
  end
end