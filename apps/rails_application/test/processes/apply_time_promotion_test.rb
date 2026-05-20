require "test_helper"

module Processes
  class ApplyTimePromotionTest < ProcessTest
    cover "Processes::ApplyTimePromotion*"

    def test_applies_time_promotion_when_active_promotion_exists
      create_active_time_promotion(store_id, 50)

      given([offer_registered, price_item_added], process:)

      assert_command(Pricing::SetTimePromotionDiscount.new(order_id: order_id, amount: 50))
    end

    def test_removes_time_promotion_when_no_active_promotion
      given([offer_registered, price_item_added], process:)

      assert_command(Pricing::RemoveTimePromotionDiscount.new(order_id: order_id))
    end

    def test_does_nothing_when_order_has_no_store
      given([price_item_added], process:)

      assert_no_command
    end

    def test_rescues_not_possible_to_assign_discount_twice
      create_active_time_promotion(store_id, 50)
      failing_process = ApplyTimePromotion.new(event_store, FailingCommandBus.new(Pricing::NotPossibleToAssignDiscountTwice))

      given([offer_registered, price_item_added], process: failing_process)
    end

    def test_rescues_not_possible_to_remove_without_discount
      failing_process = ApplyTimePromotion.new(event_store, FailingCommandBus.new(Pricing::NotPossibleToRemoveWithoutDiscount))

      given([offer_registered, price_item_added], process: failing_process)
    end

    def test_selects_biggest_promotion_when_multiple_active
      create_active_time_promotion(store_id, 30)
      create_active_time_promotion(store_id, 50)
      create_active_time_promotion(store_id, 20)

      given([offer_registered, price_item_added], process:)

      assert_command(Pricing::SetTimePromotionDiscount.new(order_id: order_id, amount: 50))
    end

    private

    def process
      ApplyTimePromotion.new(event_store, command_bus)
    end

    class FailingCommandBus
      def initialize(exception_class)
        @exception_class = exception_class
      end

      def call(command)
        raise @exception_class
      end
    end

    def store_id
      @store_id ||= SecureRandom.uuid
    end

    def offer_registered
      Stores::OfferRegistered.new(data: { order_id: order_id, store_id: store_id })
    end

    def price_item_added
      Pricing::PriceItemAdded.new(data: {
        order_id: order_id,
        product_id: SecureRandom.uuid,
        base_price: 100,
        price: 100
      })
    end

    def create_active_time_promotion(store_id, discount)
      time_promotion_id = SecureRandom.uuid
      start_time = Time.current - 1.hour
      end_time = Time.current + 1.hour

      event_store.publish(
        Pricing::TimePromotionCreated.new(data: {
          time_promotion_id: time_promotion_id,
          start_time: start_time,
          end_time: end_time,
          discount: discount,
          label: "Test Promotion"
        }),
        stream_name: "Pricing::TimePromotion$#{time_promotion_id}"
      )

      event_store.publish(
        Stores::TimePromotionRegistered.new(data: {
          store_id: store_id,
          time_promotion_id: time_promotion_id
        }),
        stream_name: "Stores::Store$#{store_id}"
      )
    end
  end
end
