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
      assert_published_within(
        OrderTotalValueCalculated,
        { order_id: order_id, discounted_amount: 50, total_amount: 50 }
      ) { add_item(order_id, product_2_id) }
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
        Pricing::PercentageDiscountSet.new(
          data: {
            order_id: order_id,
            type: Discounts::TIME_PROMOTION_DISCOUNT,
            amount: 25,
            base_total_value: 0,
            total_value: 0
          }
        )
      ) { set_time_promotion_discount(order_id, 25) }
    end

    def test_does_not_set_the_same_time_promotion_discount_twice
      order_id = SecureRandom.uuid
      create_active_time_promotion(25)
      set_time_promotion_discount(order_id, 25)

      assert_raises(NotPossibleToAssignDiscountTwice) do
        set_time_promotion_discount(order_id, 25)
      end
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
            type: Discounts::TIME_PROMOTION_DISCOUNT,
            base_total_value: 0,
            total_value: 0
          }
        )
      ) { remove_time_promotion_discount(order_id) }
    end

    def test_does_not_remove_time_promotion_discount_if_there_is_none
      order_id = SecureRandom.uuid

      assert_raises(NotPossibleToRemoveWithoutDiscount) do
        remove_time_promotion_discount(order_id)
      end
    end

    def test_calculates_total_value_with_discount
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      stream = stream_name(order_id)
      assert_published_within(
        OrderTotalValueCalculated,
        { order_id: order_id, discounted_amount: 20, total_amount: 20 }
      ) { add_item(order_id, product_1_id) }
      assert_events_contain(
        stream,
        PercentageDiscountSet.new(
          data: {
            order_id: order_id,
            type: Pricing::Discounts::GENERAL_DISCOUNT,
            amount: 10,
            base_total_value: 20,
            total_value: 18
          }
        )
      ) do
        run_command(
          Pricing::SetPercentageDiscount.new(
            order_id: order_id,
            type: Pricing::Discounts::GENERAL_DISCOUNT,
            amount: 10
          )
        )
      end
      assert_published_within(
        OrderTotalValueCalculated,
        { order_id: order_id, discounted_amount: 10, total_amount: 20 }
      ) do
        assert_events_contain(
          stream,
          PercentageDiscountChanged.new(
            data: {
              order_id: order_id,
              type: Pricing::Discounts::GENERAL_DISCOUNT,
              amount: 50,
              base_total_value: 20,
              total_value: 10
            }
          )
        ) do
          run_command(
            Pricing::ChangePercentageDiscount.new(
              order_id: order_id,
              amount: 50
            )
          )
        end
      end
      assert_published_within(
        OrderTotalValueCalculated,
        { order_id: order_id, discounted_amount: 20, total_amount: 20 }
      ) do
        assert_events_contain(
          stream,
          PercentageDiscountRemoved.new(
            data: {
              order_id: order_id,
              type: Pricing::Discounts::GENERAL_DISCOUNT,
              base_total_value: 20,
              total_value: 20
            }
          )
        ) do
          run_command(
            Pricing::RemovePercentageDiscount.new(
              order_id: order_id,
              type: Pricing::Discounts::GENERAL_DISCOUNT
            )
          )
        end
      end
    end

    def test_calculates_total_value_with_100_discount
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      stream = stream_name(order_id)
      assert_published_within(
        OrderTotalValueCalculated,
        { order_id: order_id, discounted_amount: 0, total_amount: 20 }
      ) do
        assert_events_contain(
          stream,
          PercentageDiscountSet.new(
            data: {
              order_id: order_id,
              type: Pricing::Discounts::GENERAL_DISCOUNT,
              amount: 100,
              base_total_value: 20,
              total_value: 0
            }
          )
        ) do
          run_command(
            Pricing::SetPercentageDiscount.new(order_id: order_id, amount: 100)
          )
        end
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
      run_command(Pricing::RemovePercentageDiscount.new(order_id: order_id))

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

      assert_published_within(
        OrderTotalValueCalculated,
        { order_id: order_id, discounted_amount: 0, total_amount: 20 }
      ) do
        assert_events_contain(
          stream,
          PercentageDiscountChanged.new(
            data: {
              order_id: order_id,
              type: Pricing::Discounts::GENERAL_DISCOUNT,
              amount: 100,
              base_total_value: 20,
              total_value: 0
            }
          )
        ) do
          run_command(
            Pricing::ChangePercentageDiscount.new(
              order_id: order_id,
              amount: 100
            )
          )
        end
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

      assert_published_within(
        OrderTotalValueCalculated,
        { order_id: order_id, discounted_amount: 0, total_amount: 20 }
      ) do
        assert_events_contain(
          stream,
          PercentageDiscountChanged.new(
            data: {
              order_id: order_id,
              type: Pricing::Discounts::GENERAL_DISCOUNT,
              amount: 100,
              base_total_value: 20,
              total_value: 0
            }
          )
        ) do
          run_command(
            Pricing::ChangePercentageDiscount.new(
              order_id: order_id,
              amount: 100
            )
          )
        end
      end
    end

    def test_removing_discount_possible_when_discount_has_been_set_and_then_changed
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      stream = stream_name(order_id)
      run_command(
        Pricing::SetPercentageDiscount.new(
          order_id: order_id,
          type: Discounts::GENERAL_DISCOUNT,
          amount: 10
        )
      )
      run_command(
        Pricing::ChangePercentageDiscount.new(
          order_id: order_id,
          type: Discounts::GENERAL_DISCOUNT,
          amount: 20
        )
      )

      assert_published_within(
        OrderTotalValueCalculated,
        { order_id: order_id, discounted_amount: 20, total_amount: 20 }
      ) do
        assert_events_contain(
          stream,
          PercentageDiscountRemoved.new(
            data: {
              order_id: order_id,
              type: Discounts::GENERAL_DISCOUNT,
              base_total_value: 20,
              total_value: 20
            }
          )
        ) do
          run_command(
            Pricing::RemovePercentageDiscount.new(
              order_id: order_id,
              type: Discounts::GENERAL_DISCOUNT
            )
          )
        end
      end
    end

    def test_removing_with_missing_discount_not_possible
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      assert_raises NotPossibleToRemoveWithoutDiscount do
        run_command(Pricing::RemovePercentageDiscount.new(order_id: order_id))
      end
      run_command(
        Pricing::SetPercentageDiscount.new(order_id: order_id, amount: 10)
      )
      run_command(Pricing::RemovePercentageDiscount.new(order_id: order_id))
      assert_raises NotPossibleToRemoveWithoutDiscount do
        run_command(Pricing::RemovePercentageDiscount.new(order_id: order_id))
      end
    end

    private

    def stream_name(order_id)
      "Pricing::Offer$#{order_id}"
    end

    def calculate_sub_amounts(order_id)
      run_command(CalculateSubAmounts.new(order_id: order_id))
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
