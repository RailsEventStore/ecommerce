require "test_helper"

module TimePromotions
  class CreateTimePromotionTest < InMemoryTestCase
    cover "TimePromotions::CreateTimePromotion*"

    def configure(event_store, _command_bus)
      TimePromotions::Configuration.new.call(event_store)
    end

    def test_creates_record_with_event_attributes_on_matching_id
      other_id = SecureRandom.uuid
      id = SecureRandom.uuid
      start_time = Time.utc(2026, 6, 1, 10, 0, 0)
      end_time = Time.utc(2026, 6, 1, 12, 0, 0)

      publish_created(other_id, 20, Time.utc(2027, 1, 1), Time.utc(2027, 1, 2), "Other")
      publish_created(id, 15, start_time, end_time, "Summer Sale")

      record = TimePromotions.time_promotions_for_store(nil).find(id)

      assert_equal("Summer Sale", record.label)
      assert_equal(15, record.discount)
      assert_equal(start_time, record.start_time)
      assert_equal(end_time, record.end_time)
    end

    private

    def publish_created(id, discount, start_time, end_time, label)
      event_store.publish(
        Pricing::TimePromotionCreated.new(
          data: { time_promotion_id: id, discount: discount, start_time: start_time, end_time: end_time, label: label }
        )
      )
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
