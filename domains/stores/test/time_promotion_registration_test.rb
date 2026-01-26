require_relative 'test_helper'
module Stores
  class TimePromotionRegistrationTest < Test
    cover "Stores*"

    def test_time_promotion_should_get_registered
      store_id = SecureRandom.uuid
      time_promotion_id = SecureRandom.uuid
      assert register_time_promotion(store_id, time_promotion_id)
    end

    def test_should_publish_event
      store_id = SecureRandom.uuid
      time_promotion_id = SecureRandom.uuid
      time_promotion_registered = Stores::TimePromotionRegistered.new(data: { store_id: store_id, time_promotion_id: time_promotion_id })
      assert_events("Stores::Store$#{store_id}", time_promotion_registered) do
        register_time_promotion(store_id, time_promotion_id)
      end
    end

    private

    def register_time_promotion(store_id, time_promotion_id)
      run_command(RegisterTimePromotion.new(store_id: store_id, time_promotion_id: time_promotion_id))
    end
  end
end
