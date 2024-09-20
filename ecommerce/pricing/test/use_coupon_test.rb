require_relative "test_helper"

module Pricing
  class UseCouponTest < Test
    cover "Pricing*"

    def test_coupon_is_used
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      coupon_id = SecureRandom.uuid
      register_coupon(coupon_id, "Coupon", "coupon10", 10)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)

      assert_events_contain(
        stream_name(order_id),
        CouponUsed.new(
          data: {
            order_id: order_id,
            coupon_id: coupon_id,
            discount: 10
          }
        )
      ) do
        run_command(
          Pricing::UseCoupon.new(order_id: order_id, coupon_id: coupon_id, discount: 10)
        )
      end
    end

    private

    def stream_name(id)
      "Pricing::Offer$#{id}"
    end

  end
end
