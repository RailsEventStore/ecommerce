require "test_helper"

module Processes
  class PromotionsCalendarTest < ProcessTest
    cover "Processes::PromotionsCalendar*"

    def test_returns_no_discount_when_no_promotions
      store_id = SecureRandom.uuid
      calendar = PromotionsCalendar.new(event_store, store_id)

      discount = calendar.current_time_promotions_discount

      assert_instance_of(Pricing::Discounts::NoPercentageDiscount, discount)
    end

    def test_returns_discount_when_one_active_promotion
      store_id = SecureRandom.uuid
      create_time_promotion(store_id, 25, Time.current - 1.hour, Time.current + 1.hour)

      calendar = PromotionsCalendar.new(event_store, store_id)
      discount = calendar.current_time_promotions_discount

      assert_instance_of(Pricing::Discounts::PercentageDiscount, discount)
      assert_equal(25, discount.value)
    end

    def test_returns_biggest_discount_when_multiple_active_promotions
      store_id = SecureRandom.uuid
      create_time_promotion(store_id, 30, Time.current - 1.hour, Time.current + 1.hour)
      create_time_promotion(store_id, 50, Time.current - 2.hours, Time.current + 2.hours)
      create_time_promotion(store_id, 20, Time.current - 30.minutes, Time.current + 30.minutes)

      calendar = PromotionsCalendar.new(event_store, store_id)
      discount = calendar.current_time_promotions_discount

      assert_equal(50, discount.value)
    end

    def test_returns_no_discount_when_promotion_not_started
      store_id = SecureRandom.uuid
      create_time_promotion(store_id, 40, Time.current + 1.hour, Time.current + 2.hours)

      calendar = PromotionsCalendar.new(event_store, store_id)
      discount = calendar.current_time_promotions_discount

      assert_instance_of(Pricing::Discounts::NoPercentageDiscount, discount)
    end

    def test_returns_no_discount_when_promotion_ended
      store_id = SecureRandom.uuid
      create_time_promotion(store_id, 40, Time.current - 2.hours, Time.current - 1.hour)

      calendar = PromotionsCalendar.new(event_store, store_id)
      discount = calendar.current_time_promotions_discount

      assert_instance_of(Pricing::Discounts::NoPercentageDiscount, discount)
    end

    def test_ignores_promotions_from_other_stores
      store_id = SecureRandom.uuid
      other_store_id = SecureRandom.uuid
      create_time_promotion(other_store_id, 50, Time.current - 1.hour, Time.current + 1.hour)

      calendar = PromotionsCalendar.new(event_store, store_id)
      discount = calendar.current_time_promotions_discount

      assert_instance_of(Pricing::Discounts::NoPercentageDiscount, discount)
    end

    def test_handles_registered_promotion_without_created_event
      store_id = SecureRandom.uuid
      time_promotion_id = SecureRandom.uuid

      event_store.publish(
        Stores::TimePromotionRegistered.new(data: {
          store_id: store_id,
          time_promotion_id: time_promotion_id
        }),
        stream_name: "Stores::Store$#{store_id}"
      )

      calendar = PromotionsCalendar.new(event_store, store_id)
      discount = calendar.current_time_promotions_discount

      assert_instance_of(Pricing::Discounts::NoPercentageDiscount, discount)
    end

    def test_promotion_running_at_start_time
      store_id = SecureRandom.uuid
      start_time = Time.current
      end_time = Time.current + 1.hour
      create_time_promotion(store_id, 30, start_time, end_time)

      calendar = PromotionsCalendar.new(event_store, store_id)
      discount = calendar.current_time_promotions_discount

      assert_equal(30, discount.value)
    end

    def test_promotion_not_running_at_end_time
      store_id = SecureRandom.uuid
      start_time = Time.current - 1.hour
      end_time = Time.current
      create_time_promotion(store_id, 30, start_time, end_time)

      calendar = PromotionsCalendar.new(event_store, store_id)
      discount = calendar.current_time_promotions_discount

      assert_instance_of(Pricing::Discounts::NoPercentageDiscount, discount)
    end

    def test_combines_active_and_inactive_promotions
      store_id = SecureRandom.uuid
      create_time_promotion(store_id, 10, Time.current - 3.hours, Time.current - 2.hours)
      create_time_promotion(store_id, 50, Time.current - 1.hour, Time.current + 1.hour)
      create_time_promotion(store_id, 20, Time.current + 2.hours, Time.current + 3.hours)

      calendar = PromotionsCalendar.new(event_store, store_id)
      discount = calendar.current_time_promotions_discount

      assert_equal(50, discount.value)
    end

    def test_ignores_other_event_types_in_store_stream
      store_id = SecureRandom.uuid

      event_store.publish(
        Stores::StoreRegistered.new(data: {store_id: store_id, name: "Store"}),
        stream_name: "Stores::Store$#{store_id}"
      )

      create_time_promotion(store_id, 30, Time.current - 1.hour, Time.current + 1.hour)

      calendar = PromotionsCalendar.new(event_store, store_id)
      discount = calendar.current_time_promotions_discount

      assert_equal(30, discount.value)
    end

    def test_end_time_is_exclusive
      store_id = SecureRandom.uuid
      fixed_time = Time.utc(2024, 1, 1, 12, 0, 0)
      create_time_promotion(store_id, 40, fixed_time - 1.hour, fixed_time)

      calendar = PromotionsCalendar.new(event_store, store_id)
      discount = calendar.current_time_promotions_discount(fixed_time)

      assert_instance_of(Pricing::Discounts::NoPercentageDiscount, discount)
    end

    def test_start_time_is_inclusive
      store_id = SecureRandom.uuid
      fixed_time = Time.utc(2024, 1, 1, 12, 0, 0)
      create_time_promotion(store_id, 40, fixed_time, fixed_time + 1.hour)

      calendar = PromotionsCalendar.new(event_store, store_id)
      discount = calendar.current_time_promotions_discount(fixed_time)

      assert_equal(40, discount.value)
    end

    def test_ignores_other_event_types_in_promotion_stream
      store_id = SecureRandom.uuid
      time_promotion_id = SecureRandom.uuid

      event_store.publish(
        Pricing::PriceSet.new(data: { product_id: SecureRandom.uuid, price: 100 }),
        stream_name: "Pricing::TimePromotion$#{time_promotion_id}"
      )

      event_store.publish(
        Stores::TimePromotionRegistered.new(data: {
          store_id: store_id,
          time_promotion_id: time_promotion_id
        }),
        stream_name: "Stores::Store$#{store_id}"
      )

      calendar = PromotionsCalendar.new(event_store, store_id)
      discount = calendar.current_time_promotions_discount

      assert_instance_of(Pricing::Discounts::NoPercentageDiscount, discount)
    end

    private

    def create_time_promotion(store_id, discount, start_time, end_time)
      time_promotion_id = SecureRandom.uuid

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
