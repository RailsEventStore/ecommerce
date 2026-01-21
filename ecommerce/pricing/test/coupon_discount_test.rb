require_relative "test_helper"

module Pricing
  class CouponDiscountTest < Test
    cover "Pricing::CouponDiscount*"

    def test_rejects_zero
      assert_raises(CouponDiscount::UnacceptableRange) { CouponDiscount.parse("0") }
    end

    def test_rejects_negative
      assert_raises(CouponDiscount::UnacceptableRange) { CouponDiscount.parse("-0.01") }
    end

    def test_rejects_over_100
      assert_raises(CouponDiscount::UnacceptableRange) { CouponDiscount.parse("100.01") }
    end

    def test_rejects_non_numeric
      assert_raises(CouponDiscount::Unparseable) { CouponDiscount.parse("abc") }
    end

    def test_accepts_string_decimal
      discount = CouponDiscount.parse("0.01")
      assert_equal(BigDecimal("0.01"), discount.to_d)
    end
  end
end