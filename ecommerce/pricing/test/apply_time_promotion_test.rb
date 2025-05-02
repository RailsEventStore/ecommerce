require_relative "test_helper"

module Pricing
  class ApplyTimePromotionTest < Test
    cover "Pricing*"

    def test_applies_biggest_time_promotion_discount

      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      create_inactive_time_promotion(60)
      create_active_time_promotion(10)
      create_active_time_promotion(50)
      create_active_time_promotion(30)

      assert_events_contain(stream_name(order_id), percentage_discount_set_event(order_id, 50)) do
        Pricing::ApplyTimePromotion.new.call(item_added_to_basket_event(order_id, product_id))
      end
    end

    def test_removes_time_promotion_discount
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      create_active_time_promotion(50)
      set_time_promotion_discount(order_id, 50)

      Timecop.travel(1.minute.from_now) do
        assert_events_contain(stream_name(order_id), percentage_discount_removed_event(order_id)) do
          Pricing::ApplyTimePromotion.new.call(item_added_to_basket_event(order_id, product_id))
        end
      end
    end

    private

    def create_inactive_time_promotion(discount)
      run_command(
        Pricing::CreateTimePromotion.new(
          time_promotion_id: SecureRandom.uuid,
          discount: discount,
          start_time: Time.current - 2,
          end_time: Time.current - 1,
          label: "Past Promotion"
        )
      )
    end

    def create_active_time_promotion(discount)
      run_command(
        Pricing::CreateTimePromotion.new(
          time_promotion_id: SecureRandom.uuid,
          discount: discount,
          start_time: Time.current - 1,
          end_time: Time.current + 1,
          label: "Last Minute"
        )
      )
    end

    def item_added_to_basket_event(order_id, product_id)
      price_item_added = Pricing::PriceItemAdded.new(
        data: {
          product_id: product_id,
          order_id: order_id,
          base_price: 1000,
          price: 1000,
          base_total_value: 1000,
          total_value: 1000
          }
        )
      event_store.append(price_item_added, stream_name: stream_name(order_id))
      price_item_added
    end

    def set_time_promotion_discount(order_id, discount)
      run_command(SetTimePromotionDiscount.new(order_id: order_id, amount: discount))
    end

    def percentage_discount_set_event(order_id, amount)
      PercentageDiscountSet.new(
        data: {
          order_id: order_id,
          type: Pricing::Discounts::TIME_PROMOTION_DISCOUNT,
          amount: amount,
          base_total_value: 1000,
          total_value: 500
        }
      )
    end

    def percentage_discount_removed_event(order_id)
      PercentageDiscountRemoved.new(
        data: {
          order_id: order_id,
          type: Pricing::Discounts::TIME_PROMOTION_DISCOUNT,
          base_total_value: 1000,
          total_value: 1000
        }
      )
    end

    def stream_name(order_id)
      "Pricing::Offer$#{order_id}"
    end
  end
end
