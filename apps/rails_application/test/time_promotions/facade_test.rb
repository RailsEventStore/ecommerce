require "test_helper"

module TimePromotions
  class FacadeTest < InMemoryTestCase
    cover "TimePromotions.time_promotions_for_store"
    cover "TimePromotions.current_time_promotions_for_store"

    def configure(event_store, _command_bus)
      TimePromotions::Configuration.new.call(event_store)
    end

    def test_time_promotions_for_store_returns_only_promotions_from_given_store
      store_1_id = SecureRandom.uuid
      store_2_id = SecureRandom.uuid
      promotion_1_id = create_and_assign(store_1_id, 10, Time.current - 1.hour, Time.current + 1.hour, "In store 1")
      promotion_2_id = create_and_assign(store_1_id, 20, Time.current - 1.hour, Time.current + 1.hour, "Also store 1")
      promotion_3_id = create_and_assign(store_2_id, 30, Time.current - 1.hour, Time.current + 1.hour, "In store 2")

      result = TimePromotions.time_promotions_for_store(store_1_id)

      assert_equal(2, result.count)
      assert_equal([promotion_1_id, promotion_2_id].sort, result.pluck(:id).sort)
    end

    def test_current_time_promotions_for_store_excludes_expired_promotions
      store_id = SecureRandom.uuid
      current_id = create_and_assign(store_id, 10, Time.current - 1.hour, Time.current + 1.hour, "Current")
      create_and_assign(store_id, 20, Time.current - 2.hours, Time.current - 1.hour, "Expired")
      create_and_assign(store_id, 30, Time.current + 1.hour, Time.current + 2.hours, "Upcoming")

      result = TimePromotions.current_time_promotions_for_store(store_id)

      assert_equal([current_id], result.pluck(:id))
    end

    def test_current_time_promotions_for_store_excludes_other_stores
      store_id = SecureRandom.uuid
      other_store_id = SecureRandom.uuid
      mine_id = create_and_assign(store_id, 10, Time.current - 1.hour, Time.current + 1.hour, "Mine")
      create_and_assign(other_store_id, 20, Time.current - 1.hour, Time.current + 1.hour, "Theirs")

      result = TimePromotions.current_time_promotions_for_store(store_id)

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
