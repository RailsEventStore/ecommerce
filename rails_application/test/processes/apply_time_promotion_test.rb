require "test_helper"

module Processes
  class ApplyTimePromotionTest < ProcessTest
    cover "Processes::ApplyTimePromotion"

    def test_applies_time_promotion_when_active_promotion_exists
      store_id = SecureRandom.uuid
      order_repository = fake_order_repository(order_id, store_id)
      create_active_time_promotion(store_id, 50)

      process = ApplyTimePromotion.new(command_bus, event_store, order_repository)
      process.call(price_item_added)

      assert_command(Pricing::SetTimePromotionDiscount.new(order_id: order_id, amount: 50))
    end

    def test_removes_time_promotion_when_no_active_promotion
      store_id = SecureRandom.uuid
      order_repository = fake_order_repository(order_id, store_id)

      process = ApplyTimePromotion.new(command_bus, event_store, order_repository)
      process.call(price_item_added)

      assert_command(Pricing::RemoveTimePromotionDiscount.new(order_id: order_id))
    end

    def test_does_nothing_when_order_has_no_store
      order_repository = fake_order_repository(order_id, nil)

      process = ApplyTimePromotion.new(command_bus, event_store, order_repository)
      process.call(price_item_added)

      assert_no_command
    end

    def test_rescues_not_possible_to_assign_discount_twice
      store_id = SecureRandom.uuid
      order_repository = fake_order_repository(order_id, store_id)
      create_active_time_promotion(store_id, 50)

      failing_command_bus = FailingCommandBus.new(Pricing::NotPossibleToAssignDiscountTwice)
      process = ApplyTimePromotion.new(failing_command_bus, event_store, order_repository)

      process.call(price_item_added)
    end

    def test_rescues_not_possible_to_remove_without_discount
      store_id = SecureRandom.uuid
      order_repository = fake_order_repository(order_id, store_id)

      failing_command_bus = FailingCommandBus.new(Pricing::NotPossibleToRemoveWithoutDiscount)
      process = ApplyTimePromotion.new(failing_command_bus, event_store, order_repository)

      process.call(price_item_added)
    end

    def test_selects_biggest_promotion_when_multiple_active
      store_id = SecureRandom.uuid
      order_repository = fake_order_repository(order_id, store_id)
      create_active_time_promotion(store_id, 30)
      create_active_time_promotion(store_id, 50)
      create_active_time_promotion(store_id, 20)

      process = ApplyTimePromotion.new(command_bus, event_store, order_repository)
      process.call(price_item_added)

      assert_command(Pricing::SetTimePromotionDiscount.new(order_id: order_id, amount: 50))
    end

    private

    class FailingCommandBus
      def initialize(exception_class)
        @exception_class = exception_class
      end

      def call(command)
        raise @exception_class
      end
    end

    def fake_order_repository(expected_order_id, store_id)
      FakeOrderRepository.new(expected_order_id, store_id)
    end

    class FakeOrderRepository
      def initialize(expected_order_id, store_id)
        @expected_order_id = expected_order_id
        @store_id = store_id
      end

      def store_id_for_order(order_id)
        order_id == @expected_order_id ? @store_id : nil
      end
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

    def price_item_added
      Pricing::PriceItemAdded.new(data: {
        order_id: order_id,
        product_id: SecureRandom.uuid,
        base_price: 100,
        price: 100
      })
    end
  end
end
