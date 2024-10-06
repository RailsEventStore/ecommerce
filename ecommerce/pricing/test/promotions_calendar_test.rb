require_relative "test_helper"

module Pricing
  class PromotionsCalendarTest < Test
    cover "Pricing::PromotionsCalendar*"

    def test_time_promotion_running
      time_current = Time.current
      promotion = Pricing::PromotionsCalendar::Promotion.from_event(time_promotion_created_event(time_current))

      assert(promotion.running?(time_current))
      refute(promotion.running?(time_current + 1))
      refute(promotion.running?(time_current - 2))
      refute(promotion.running?(time_current + 2))
    end

    private

    def time_promotion_created_event(time_current)
      TimePromotionCreated.new(
        data: {
          time_promotion_id: SecureRandom.uuid,
          start_time: time_current - 1,
          end_time: time_current + 1,
          discount: 10
        }
      )
    end
  end
end
