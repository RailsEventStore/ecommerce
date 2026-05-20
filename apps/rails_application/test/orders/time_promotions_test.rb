require "test_helper"

module Orders
  class TimePromotionsTest < InMemoryTestCase
    cover "Orders::CreateTimePromotion*"
    cover "Orders::AssignStoreToTimePromotion*"
    cover "Orders.current_time_promotions_for_store"

    def configure(event_store, _command_bus)
      Orders::Configuration.new.call(event_store)
    end

    def test_returns_active_promotion_with_its_attributes
      store_id = SecureRandom.uuid
      promotion_id = create_and_assign(store_id, 10, Time.current - 1.hour, Time.current + 1.hour, "Current")

      result = Orders.current_time_promotions_for_store(store_id)

      assert_equal([promotion_id], result.pluck(:id))
      assert_equal(10, result.first.discount)
      assert_equal("Current", result.first.label)
    end

    def test_excludes_expired_and_upcoming_promotions
      store_id = SecureRandom.uuid
      current_id = create_and_assign(store_id, 10, Time.current - 1.hour, Time.current + 1.hour, "Current")
      create_and_assign(store_id, 20, Time.current - 2.hours, Time.current - 1.hour, "Expired")
      create_and_assign(store_id, 30, Time.current + 1.hour, Time.current + 2.hours, "Upcoming")

      result = Orders.current_time_promotions_for_store(store_id)

      assert_equal([current_id], result.pluck(:id))
    end

    def test_excludes_promotions_from_other_stores
      store_id = SecureRandom.uuid
      other_store_id = SecureRandom.uuid
      mine_id = create_and_assign(store_id, 10, Time.current - 1.hour, Time.current + 1.hour, "Mine")
      create_and_assign(other_store_id, 20, Time.current - 1.hour, Time.current + 1.hour, "Theirs")

      result = Orders.current_time_promotions_for_store(store_id)

      assert_equal([mine_id], result.pluck(:id))
    end

    private

    def create_and_assign(store_id, discount, start_time, end_time, label)
      time_promotion_id = SecureRandom.uuid
      event_store.publish(
        Pricing::TimePromotionCreated.new(
          data: { time_promotion_id: time_promotion_id, discount: discount, start_time: start_time, end_time: end_time, label: label }
        )
      )
      event_store.publish(
        Stores::TimePromotionRegistered.new(data: { time_promotion_id: time_promotion_id, store_id: store_id })
      )
      time_promotion_id
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
