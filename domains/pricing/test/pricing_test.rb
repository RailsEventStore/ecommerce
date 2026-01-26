require_relative "test_helper"

module Pricing
  class PricingTest < Test
    cover "Pricing*"

    def test_sets_time_promotion_discount
      order_id = SecureRandom.uuid
      stream = stream_name(order_id)

      assert_events_contain(
        stream,
        Pricing::PercentageDiscountSet.new(
          data: {
            order_id: order_id,
            type: Discounts::TIME_PROMOTION_DISCOUNT,
            amount: 25
          }
        )
      ) { set_time_promotion_discount(order_id, 25) }
    end

    def test_does_not_set_the_same_time_promotion_discount_twice
      order_id = SecureRandom.uuid
      create_active_time_promotion(25)
      set_time_promotion_discount(order_id, 25)

      assert_raises(NotPossibleToAssignDiscountTwice) { set_time_promotion_discount(order_id, 25) }
    end

    def test_removes_time_promotion_discount
      order_id = SecureRandom.uuid
      stream = stream_name(order_id)
      create_active_time_promotion(25)
      set_time_promotion_discount(order_id, 25)

      assert_events_contain(
        stream,
        PercentageDiscountRemoved.new(
          data: {
            order_id: order_id,
            type: Discounts::TIME_PROMOTION_DISCOUNT
          }
        )
      ) { remove_time_promotion_discount(order_id) }
    end

    def test_does_not_remove_time_promotion_discount_if_there_is_none
      order_id = SecureRandom.uuid

      assert_raises(NotPossibleToRemoveWithoutDiscount) { remove_time_promotion_discount(order_id) }
    end

    def test_calculates_total_value_with_discount
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      stream = stream_name(order_id)
      assert_events_contain(
        stream,
        PercentageDiscountSet.new(
          data: {
            order_id: order_id,
            type: Pricing::Discounts::GENERAL_DISCOUNT,
            amount: 10
          }
        )
      ) do
        run_command(
          Pricing::SetPercentageDiscount.new(order_id: order_id, type: Pricing::Discounts::GENERAL_DISCOUNT, amount: 10)
        )
      end
      assert_events_contain(
        stream,
        PercentageDiscountChanged.new(
          data: {
            order_id: order_id,
            type: Pricing::Discounts::GENERAL_DISCOUNT,
            amount: 50
          }
        )
      ) do
        run_command(
          Pricing::ChangePercentageDiscount.new(order_id: order_id, amount: 50)
        )
      end
      assert_events_contain(
        stream,
        PercentageDiscountRemoved.new(
          data: {
            order_id: order_id,
            type: Pricing::Discounts::GENERAL_DISCOUNT
          }
        )
      ) do
        run_command(
          Pricing::RemovePercentageDiscount.new(order_id: order_id, type: Pricing::Discounts::GENERAL_DISCOUNT)
        )
      end
    end

    def test_calculates_total_value_with_100_discount
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      stream = stream_name(order_id)
      assert_events_contain(
        stream,
        PercentageDiscountSet.new(
          data: {
            order_id: order_id,
            type: Pricing::Discounts::GENERAL_DISCOUNT,
            amount: 100
          }
        )
      ) do
        run_command(
          Pricing::SetPercentageDiscount.new(order_id: order_id, amount: 100)
        )
      end
    end

    def test_setting_discounts_twice_not_possible_because_we_want_explicit_discount_change_command
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      run_command(
        Pricing::SetPercentageDiscount.new(order_id: order_id, amount: 10)
      )
      assert_raises NotPossibleToAssignDiscountTwice do
        run_command(
          Pricing::SetPercentageDiscount.new(order_id: order_id, amount: 20)
        )
      end
    end

    def test_setting_discount_not_possible_when_discount_has_been_set_and_then_changed
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      run_command(
        Pricing::SetPercentageDiscount.new(order_id: order_id, amount: 10)
      )
      run_command(
        Pricing::ChangePercentageDiscount.new(order_id: order_id, amount: 20)
      )

      assert_raises NotPossibleToAssignDiscountTwice do
        run_command(
          Pricing::SetPercentageDiscount.new(order_id: order_id, amount: 20)
        )
      end
    end

    def test_changing_discount_not_possible_when_discount_is_not_set
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)

      assert_raises NotPossibleToChangeDiscount do
        run_command(
          Pricing::ChangePercentageDiscount.new(order_id: order_id, amount: 20)
        )
      end
    end

    def test_changing_discount_not_possible_when_discount_is_removed
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      run_command(
        Pricing::SetPercentageDiscount.new(order_id: order_id, amount: 10)
      )
      run_command(
        Pricing::RemovePercentageDiscount.new(order_id: order_id)
      )

      assert_raises NotPossibleToChangeDiscount do
        run_command(
          Pricing::ChangePercentageDiscount.new(order_id: order_id, amount: 20)
        )
      end
    end

    def test_changing_discount_possible_when_discount_is_set
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      stream = stream_name(order_id)
      run_command(
        Pricing::SetPercentageDiscount.new(order_id: order_id, amount: 10)
      )

      assert_events_contain(
        stream,
        PercentageDiscountChanged.new(
          data: {
            order_id: order_id,
            type: Pricing::Discounts::GENERAL_DISCOUNT,
            amount: 100
          }
        )
      ) do
        run_command(
          Pricing::ChangePercentageDiscount.new(order_id: order_id, amount: 100)
        )
      end
    end

    def test_changing_discount_possible_more_than_once
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      stream = stream_name(order_id)
      run_command(
        Pricing::SetPercentageDiscount.new(order_id: order_id, amount: 10)
      )
      run_command(
        Pricing::ChangePercentageDiscount.new(order_id: order_id, amount: 20)
      )

      assert_events_contain(
        stream,
        PercentageDiscountChanged.new(
          data: {
            order_id: order_id,
            type: Pricing::Discounts::GENERAL_DISCOUNT,
            amount: 100
          }
        )
      ) do
        run_command(
          Pricing::ChangePercentageDiscount.new(order_id: order_id, amount: 100)
        )
      end
    end

    def test_removing_discount_possible_when_discount_has_been_set_and_then_changed
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      stream = stream_name(order_id)
      run_command(
        Pricing::SetPercentageDiscount.new(order_id: order_id, type: Discounts::GENERAL_DISCOUNT,amount: 10)
      )
      run_command(
        Pricing::ChangePercentageDiscount.new(order_id: order_id, type: Discounts::GENERAL_DISCOUNT, amount: 20)
      )

      assert_events_contain(
        stream,
        PercentageDiscountRemoved.new(
          data: {
            order_id: order_id,
            type: Discounts::GENERAL_DISCOUNT
          }
        )
      ) do
        run_command(
          Pricing::RemovePercentageDiscount.new(order_id: order_id, type: Discounts::GENERAL_DISCOUNT)
        )
      end
    end

    def test_removing_with_missing_discount_not_possible
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      assert_raises NotPossibleToRemoveWithoutDiscount do
        run_command(
          Pricing::RemovePercentageDiscount.new(order_id: order_id)
        )
      end
      run_command(
        Pricing::SetPercentageDiscount.new(order_id: order_id, amount: 10)
      )
      run_command(
        Pricing::RemovePercentageDiscount.new(order_id: order_id)
      )
      assert_raises NotPossibleToRemoveWithoutDiscount do
        run_command(
          Pricing::RemovePercentageDiscount.new(order_id: order_id)
        )
      end
    end

    private

    def stream_name(order_id)
      "Pricing::Offer$#{order_id}"
    end


    def create_active_time_promotion(discount)
      run_command(
        Pricing::CreateTimePromotion.new(
          time_promotion_id: SecureRandom.uuid,
          discount: discount,
          start_time: Time.current - 1.minute,
          end_time: Time.current + 1.minute,
          label: "Last Minute"
        )
      )
    end
  end
end
