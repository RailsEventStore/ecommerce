require_relative "test_helper"

module Pricing
  class PricingTest < Test
    cover "Pricing*"

    def test_configuration
      Pricing.event_store = Infra::EventStore.in_memory
      Pricing.event_store = Infra::CommandBus

      assert Pricing.event_store, Infra::EventStore.in_memory
      assert Pricing.command_bus, Infra::CommandBus
    end

    def test_calculates_total_value
      product_1_id = SecureRandom.uuid
      product_2_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      set_price(product_2_id, 30)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      add_item(order_id, product_2_id)
      stream = stream_name(order_id)
      assert_events(
        stream,
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 50,
            total_amount: 50
          }
        )
      ) { calculate_total_value(order_id) }
    end

    def test_calculates_sub_amounts
      product_1_id = SecureRandom.uuid
      product_2_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      set_price(product_2_id, 30)
      order_id = SecureRandom.uuid
      stream = stream_name(order_id)

      assert_events(stream) { calculate_sub_amounts(order_id) }

      add_item(order_id, product_1_id)
      add_item(order_id, product_2_id)
      add_item(order_id, product_2_id)
      assert_events(
        stream,
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_1_id,
            quantity: 1,
            amount: 20,
            discounted_amount: 20
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_2_id,
            quantity: 2,
            amount: 60,
            discounted_amount: 60
          }
        )
      ) { calculate_sub_amounts(order_id) }
      run_command(
        Pricing::SetPercentageDiscount.new(order_id: order_id, amount: 10)
      )
      assert_events(
        stream,
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_1_id,
            quantity: 1,
            amount: 20,
            discounted_amount: 18
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_2_id,
            quantity: 2,
            amount: 60,
            discounted_amount: 54
          }
        )
      ) { calculate_sub_amounts(order_id) }
    end

    def test_sets_time_promotion_discount
      order_id = SecureRandom.uuid
      stream = stream_name(order_id)

      assert_events_contain(
        stream,
        TimePromotionDiscountSet.new(
          data: {
            order_id: order_id,
            amount: 25
          }
        )
      ) { set_time_promotion_discount(order_id, 25) }
    end

    def test_does_not_set_the_same_time_promotion_discount_twice
      order_id = SecureRandom.uuid
      stream = stream_name(order_id)
      set_time_promotion_discount(order_id, 25)

      assert_events(stream) { set_time_promotion_discount(order_id, 25) }
    end

    def test_resets_time_promotion_discount
      order_id = SecureRandom.uuid
      stream = stream_name(order_id)
      set_time_promotion_discount(order_id, 25)


      assert_events_contain(
        stream,
        TimePromotionDiscountReset.new(
          data: {
            order_id: order_id
          }
        )
      ) { reset_time_promotion_discount(order_id) }
    end

    def test_does_not_reset_time_promotion_discount_if_there_is_none
      order_id = SecureRandom.uuid
      stream = stream_name(order_id)

      assert_events(stream) { reset_time_promotion_discount(order_id) }
    end

    def test_calculates_total_value_with_discount
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      stream = stream_name(order_id)
      assert_events(
        stream,
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 20,
            total_amount: 20
          }
        )
      ) { run_command(CalculateTotalValue.new(order_id: order_id)) }
      assert_events_contain(
        stream,
        PercentageDiscountSet.new(
          data: {
            order_id: order_id,
            amount: 10
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 18,
            total_amount: 20
          }
        )
      ) do
        run_command(
          Pricing::SetPercentageDiscount.new(order_id: order_id, amount: 10)
        )
      end
      assert_events_contain(
        stream,
        PercentageDiscountChanged.new(
          data: {
            order_id: order_id,
            amount: 50
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 10,
            total_amount: 20
          }
        )
      ) do
        run_command(
          Pricing::ChangePercentageDiscount.new(order_id: order_id, amount: 50)
        )
      end
      assert_events_contain(
        stream,
        PercentageDiscountReset.new(
          data: {
            order_id: order_id,
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 20,
            total_amount: 20
          }
        )
      ) do
        run_command(
          Pricing::ResetPercentageDiscount.new(order_id: order_id)
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
            amount: 100
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 0,
            total_amount: 20
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

    def test_changing_discount_not_possible_when_discount_is_reset
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      run_command(
        Pricing::SetPercentageDiscount.new(order_id: order_id, amount: 10)
      )
      run_command(
        Pricing::ResetPercentageDiscount.new(order_id: order_id)
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
            amount: 100
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 0,
            total_amount: 20
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
            amount: 100
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 0,
            total_amount: 20
          }
        )
      ) do
        run_command(
          Pricing::ChangePercentageDiscount.new(order_id: order_id, amount: 100)
        )
      end
    end

    def test_resetting_discount_possible_when_discount_has_been_set_and_then_changed
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
        PercentageDiscountReset.new(
          data: {
            order_id: order_id
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 20,
            total_amount: 20
          }
        )
      ) do
        run_command(
          Pricing::ResetPercentageDiscount.new(order_id: order_id)
        )
      end
    end

    def test_resetting_with_missing_discount_not_possible
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      assert_raises NotPossibleToResetWithoutDiscount do
        run_command(
          Pricing::ResetPercentageDiscount.new(order_id: order_id)
        )
      end
      run_command(
        Pricing::SetPercentageDiscount.new(order_id: order_id, amount: 10)
      )
      run_command(
        Pricing::ResetPercentageDiscount.new(order_id: order_id)
      )
      assert_raises NotPossibleToResetWithoutDiscount do
        run_command(
          Pricing::ResetPercentageDiscount.new(order_id: order_id)
        )
      end
    end

    private

    def stream_name(order_id)
      "Pricing::Offer$#{order_id}"
    end

    def calculate_sub_amounts(order_id)
      run_command(CalculateSubAmounts.new(order_id: order_id))
    end
  end
end
