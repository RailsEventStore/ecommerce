require_relative "test_helper"

module Pricing
  class MultiplePromotionTest < Test
    cover "Pricing*"

    def test_given_multiple_discounts_applied_when_time_promotion_is_removed_then_other_promotion_is_included
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      given(
        [
          TimePromotionCreated.new(
            data: {
              time_promotion_id: SecureRandom.uuid,
              discount: 10,
              start_time: Time.current - 1,
              end_time: Time.current + 1
            }
          ),
          Pricing::PriceItemAdded.new(
            data: {
              product_id: product_id,
              order_id: order_id,
              base_price: 1000,
              price: 1000,
              base_total_value: 1000,
              total_value: 1000
            }
          ),
          PercentageDiscountSet.new(
            data: {
              order_id: order_id,
              type: Discounts::TIME_PROMOTION_DISCOUNT,
              amount: 10,
              base_total_value: 1000,
              total_value: 900
            }
          ),
          PercentageDiscountSet.new(
            data: {
              order_id: order_id,
              type: Discounts::GENERAL_DISCOUNT,
              amount: 50,
              base_total_value: 1000,
              total_value: 450
            }
          )
        ]
      )

      assert_events_contain(
        stream_name(order_id),
        PercentageDiscountRemoved.new(
          data: {
            order_id: order_id,
            type: Discounts::GENERAL_DISCOUNT,
            base_total_value: 1000,
            total_value: 900
          }
        )
      ) { run_command(RemovePercentageDiscount.new(order_id: order_id)) }
    end

    private

    def given(events)
      events.each do |event|
        event_store.append(
          event,
          stream_name: stream_name(event.data[:order_id])
        )
      end
    end

    def stream_name(order_id)
      "Pricing::Offer$#{order_id}"
    end
  end
end
