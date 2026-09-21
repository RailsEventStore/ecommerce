require_relative "test_helper"

module Pricing
  class CommandsTest < Test
    cover "Pricing*"

    ORDER_ID = "123e4567-e89b-42d3-a456-426614174000"
    ENTITY_ID = "223e4567-e89b-42d3-a456-426614174000"
    TIME = Time.utc(2026, 9, 21)

    def test_exposes_and_coerces_attributes
      assert_equal(ORDER_ID, DraftOffer.new(ORDER_ID).order_id)
      assert_price_item(AddPriceItem.new(ORDER_ID, ENTITY_ID, "10.5"))
      assert_equal(ENTITY_ID, RemovePriceItem.new(ORDER_ID, ENTITY_ID).product_id)
      assert_equal(BigDecimal("10.5"), SetPrice.new(ENTITY_ID, "10.5").price)
      future_price = SetFuturePrice.new(ENTITY_ID, "10.5", TIME)
      assert_equal(BigDecimal("10.5"), future_price.price)
      assert_equal(TIME, future_price.valid_since)
      assert_equal(BigDecimal("10.5"), SetPercentageDiscount.new(ORDER_ID, "10.5").amount)
      assert_equal(BigDecimal("10.5"), SetTimePromotionDiscount.new(ORDER_ID, "10.5").amount)
      assert_equal(BigDecimal("10.5"), ChangePercentageDiscount.new(ORDER_ID, "10.5").amount)
      assert_equal(ENTITY_ID, MakeProductFreeForOrder.new(ORDER_ID, ENTITY_ID).product_id)
      assert_equal(ENTITY_ID, RemoveFreeProductFromOrder.new(ORDER_ID, ENTITY_ID).product_id)
      assert_equal(ENTITY_ID, UseCoupon.new(ORDER_ID, ENTITY_ID, 10).coupon_id)
    end

    def test_exposes_coupon_and_time_promotion_attributes
      coupon = RegisterCoupon.new(ENTITY_ID, "Coupon", "CODE", "10.5")
      assert_equal("Coupon", coupon.name)
      assert_equal("CODE", coupon.code)
      assert_equal(BigDecimal("10.5"), coupon.discount)

      promotion = CreateTimePromotion.new(ENTITY_ID, "10.5", TIME, TIME + 60, "Promotion")
      assert_equal(ENTITY_ID, promotion.time_promotion_id)
      assert_equal(BigDecimal("10.5"), promotion.discount)
      assert_equal(TIME, promotion.start_time)
      assert_equal(TIME + 60, promotion.end_time)
      assert_equal("Promotion", promotion.label)

      promotion_without_id = CreateTimePromotion.new("10.5", TIME, TIME + 60, "Promotion")
      assert_nil(promotion_without_id.time_promotion_id)
      assert_raises(Infra::Command::Invalid) { CreateTimePromotion.new(nil, "10.5", TIME, TIME + 60, "Promotion") }
    end

    def test_exposes_rejection_attributes_and_optional_product_ids
      command = RejectOffer.new(ORDER_ID, "Unavailable", [ENTITY_ID])
      assert_equal("Unavailable", command.reason)
      assert_equal([ENTITY_ID], command.unavailable_product_ids)
      assert_nil(RejectOffer.new(ORDER_ID, "Unavailable").unavailable_product_ids)
      assert_equal([], RejectOffer.new(ORDER_ID, "Unavailable", []).unavailable_product_ids)
    end

    def test_aggregate_ids
      aggregate_commands.each do |command|
        assert_equal(command.order_id, command.aggregate_id)
      end
      coupon = RegisterCoupon.new(ENTITY_ID, "Coupon", "CODE", 10)
      assert_equal(coupon.coupon_id, coupon.aggregate_id)
    end

    def test_rejects_invalid_primary_ids
      primary_id_constructors.each do |constructor|
        invalid_ids.each do |id|
          assert_raises(Infra::Command::Invalid) { constructor.call(id) }
        end
      end
    end

    def test_rejects_invalid_entity_ids
      entity_id_constructors.each do |constructor|
        invalid_ids.each do |id|
          assert_raises(Infra::Command::Invalid) { constructor.call(id) }
        end
      end
    end

    def test_price_boundaries_and_coercion
      price_constructors.each do |constructor|
        assert_equal(BigDecimal("0"), constructor.call(0))
        assert_raises(Infra::Command::Invalid) { constructor.call(-1) }
        assert_raises(Infra::Command::Invalid) { constructor.call(Object.new) }
      end
    end

    def test_discount_boundaries_and_coercion
      discount_constructors.each do |constructor|
        assert_equal(BigDecimal("0.5"), constructor.call("0.5"))
        assert_equal(BigDecimal("100"), constructor.call("100"))
        assert_raises(Infra::Command::Invalid) { constructor.call(0) }
        assert_raises(Infra::Command::Invalid) { constructor.call(101) }
        assert_raises(Infra::Command::Invalid) { constructor.call(Object.new) }
      end
    end

    def test_requires_times_and_strings
      assert_raises(Infra::Command::Invalid) { SetFuturePrice.new(ENTITY_ID, 10, "2026-09-21") }
      assert_raises(Infra::Command::Invalid) { CreateTimePromotion.new(ENTITY_ID, 10, "start", TIME, "Promotion") }
      assert_raises(Infra::Command::Invalid) { CreateTimePromotion.new(ENTITY_ID, 10, TIME, "end", "Promotion") }
      assert_raises(Infra::Command::Invalid) { CreateTimePromotion.new(ENTITY_ID, 10, TIME, TIME, Object.new) }
      assert_raises(Infra::Command::Invalid) { RegisterCoupon.new(ENTITY_ID, Object.new, "CODE", 10) }
      assert_raises(Infra::Command::Invalid) { RegisterCoupon.new(ENTITY_ID, "Coupon", Object.new, 10) }
      assert_raises(Infra::Command::Invalid) { RejectOffer.new(ORDER_ID, Object.new) }

      time = Class.new(Time).at(TIME)
      string = Class.new(String).new("value")
      assert_equal(time, SetFuturePrice.new(ENTITY_ID, 10, time).valid_since)
      assert_equal(string, RegisterCoupon.new(ENTITY_ID, string, string, 10).name)
      assert_equal(string, CreateTimePromotion.new(ENTITY_ID, 10, time, time, string).label)
      assert_equal(string, RejectOffer.new(ORDER_ID, string).reason)
    end

    def test_validates_unavailable_product_ids
      assert_raises(Infra::Command::Invalid) { RejectOffer.new(ORDER_ID, "Unavailable", "not-an-array") }
      invalid_ids.each do |id|
        assert_raises(Infra::Command::Invalid) { RejectOffer.new(ORDER_ID, "Unavailable", [id]) }
      end
      product_ids = Class.new(Array).new([ENTITY_ID])
      assert_equal(product_ids, RejectOffer.new(ORDER_ID, "Unavailable", product_ids).unavailable_product_ids)
    end

    private

    def assert_price_item(command)
      assert_equal(ORDER_ID, command.order_id)
      assert_equal(ENTITY_ID, command.product_id)
      assert_equal(BigDecimal("10.5"), command.price)
    end

    def invalid_ids
      ["not-a-uuid", Object.new, "123e4567-e89b-12d3-a456-426614174000", "123e4567-e89b-42d3-7456-426614174000"]
    end

    def primary_id_constructors
      [
        ->(id) { DraftOffer.new(id) },
        ->(id) { AddPriceItem.new(id, ENTITY_ID, 10) },
        ->(id) { RemovePriceItem.new(id, ENTITY_ID) },
        ->(id) { SetPrice.new(id, 10) },
        ->(id) { SetFuturePrice.new(id, 10, TIME) },
        ->(id) { SetPercentageDiscount.new(id, 10) },
        ->(id) { RemovePercentageDiscount.new(id) },
        ->(id) { SetTimePromotionDiscount.new(id, 10) },
        ->(id) { RemoveTimePromotionDiscount.new(id) },
        ->(id) { RegisterCoupon.new(id, "Coupon", "CODE", 10) },
        ->(id) { CreateTimePromotion.new(id, 10, TIME, TIME, "Promotion") },
        ->(id) { ChangePercentageDiscount.new(id, 10) },
        ->(id) { MakeProductFreeForOrder.new(id, ENTITY_ID) },
        ->(id) { RemoveFreeProductFromOrder.new(id, ENTITY_ID) },
        ->(id) { UseCoupon.new(id, ENTITY_ID, 10) },
        ->(id) { AcceptOffer.new(id) },
        ->(id) { RejectOffer.new(id, "Unavailable") },
        ->(id) { ExpireOffer.new(id) }
      ]
    end

    def entity_id_constructors
      [
        ->(id) { AddPriceItem.new(ORDER_ID, id, 10) },
        ->(id) { RemovePriceItem.new(ORDER_ID, id) },
        ->(id) { MakeProductFreeForOrder.new(ORDER_ID, id) },
        ->(id) { RemoveFreeProductFromOrder.new(ORDER_ID, id) },
        ->(id) { UseCoupon.new(ORDER_ID, id, 10) }
      ]
    end

    def price_constructors
      [
        ->(price) { AddPriceItem.new(ORDER_ID, ENTITY_ID, price).price },
        ->(price) { SetPrice.new(ENTITY_ID, price).price },
        ->(price) { SetFuturePrice.new(ENTITY_ID, price, TIME).price }
      ]
    end

    def discount_constructors
      [
        ->(discount) { SetPercentageDiscount.new(ORDER_ID, discount).amount },
        ->(discount) { SetTimePromotionDiscount.new(ORDER_ID, discount).amount },
        ->(discount) { RegisterCoupon.new(ENTITY_ID, "Coupon", "CODE", discount).discount },
        ->(discount) { CreateTimePromotion.new(ENTITY_ID, discount, TIME, TIME, "Promotion").discount },
        ->(discount) { ChangePercentageDiscount.new(ORDER_ID, discount).amount },
        ->(discount) { UseCoupon.new(ORDER_ID, ENTITY_ID, discount).discount }
      ]
    end

    def aggregate_commands
      [
        DraftOffer.new(ORDER_ID),
        AddPriceItem.new(ORDER_ID, ENTITY_ID, 10),
        RemovePriceItem.new(ORDER_ID, ENTITY_ID),
        SetPercentageDiscount.new(ORDER_ID, 10),
        RemovePercentageDiscount.new(ORDER_ID),
        SetTimePromotionDiscount.new(ORDER_ID, 10),
        RemoveTimePromotionDiscount.new(ORDER_ID),
        ChangePercentageDiscount.new(ORDER_ID, 10),
        MakeProductFreeForOrder.new(ORDER_ID, ENTITY_ID),
        RemoveFreeProductFromOrder.new(ORDER_ID, ENTITY_ID),
        UseCoupon.new(ORDER_ID, ENTITY_ID, 10),
        AcceptOffer.new(ORDER_ID),
        RejectOffer.new(ORDER_ID, "Unavailable"),
        ExpireOffer.new(ORDER_ID)
      ]
    end
  end
end
