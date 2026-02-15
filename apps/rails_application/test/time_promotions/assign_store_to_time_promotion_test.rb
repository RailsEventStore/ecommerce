require "test_helper"

module TimePromotions
  class AssignStoreToTimePromotionTest < InMemoryTestCase
    cover "TimePromotions*"

    def configure(event_store, _command_bus)
      TimePromotions::Configuration.new.call(event_store)
    end

    def test_store_id_is_set_when_time_promotion_registered_in_store
      event_store.publish(time_promotion_created)
      event_store.publish(time_promotion_registered_in_store)

      assert_equal(store_id, TimePromotion.find(time_promotion_id).store_id)
    end

    def test_store_id_is_nil_when_time_promotion_not_registered_in_store
      event_store.publish(time_promotion_created)

      assert_nil(TimePromotion.find(time_promotion_id).store_id)
    end

    def test_store_id_is_updated_when_time_promotion_registered_in_different_store
      store_2_id = SecureRandom.uuid

      event_store.publish(time_promotion_created)
      event_store.publish(time_promotion_registered_in_store)

      assert_equal(store_id, TimePromotion.find(time_promotion_id).store_id)

      event_store.publish(time_promotion_registered_in_different_store(store_2_id))

      assert_equal(store_2_id, TimePromotion.find(time_promotion_id).store_id)
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def time_promotion_id
      @time_promotion_id ||= SecureRandom.uuid
    end

    def store_id
      @store_id ||= SecureRandom.uuid
    end

    def time_promotion_created
      Pricing::TimePromotionCreated.new(
        data: {
          time_promotion_id: time_promotion_id,
          discount: 10,
          start_time: Time.current - 1.hour,
          end_time: Time.current + 1.hour,
          label: "Test Promotion"
        }
      )
    end

    def time_promotion_registered_in_store
      Stores::TimePromotionRegistered.new(data: { time_promotion_id: time_promotion_id, store_id: store_id })
    end

    def time_promotion_registered_in_different_store(different_store_id)
      Stores::TimePromotionRegistered.new(data: { time_promotion_id: time_promotion_id, store_id: different_store_id })
    end
  end
end
