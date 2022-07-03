require_relative "test_helper"

module Pricing
  class TimePromotionTest < Test
    cover "Pricing::TimePromotion*"

    def test_creates_time_promotion
      uid = SecureRandom.uuid
      data = {
        time_promotion_id: uid,
        label: "Last Minute",
        code: uid.slice(0..5)
      }

      run_command = -> { create_time_promotion(**data) }

      stream = "Pricing::TimePromotion$#{uid}"
      event = TimePromotionCreated.new(data: data)

      assert_events(stream, event) do
        run_command.call
      end
    end

    def test_sets_discount_for_time_promotion
      uid = SecureRandom.uuid
      initial_data = {
        time_promotion_id: uid,
        label: "Last Minute",
        code: uid.slice(0..5)
      }
      create_time_promotion(**initial_data)
      data = { time_promotion_id: uid, discount: 25 }

      run_command = -> { run_command(SetTimePromotionDiscount.new(**data)) }

      stream = "Pricing::TimePromotion$#{uid}"
      event = TimePromotionDiscountSet.new(data: data)

      assert_events(stream, event) do
        run_command.call
      end
    end

    def test_sets_range_for_time_promotion
      uid = SecureRandom.uuid
      initial_data = {
        time_promotion_id: uid,
        label: "Last Minute",
        code: uid.slice(0..5)
      }
      create_time_promotion(**initial_data)
      data = {
        time_promotion_id: uid,
        start_time: DateTime.new(2022, 7, 1, 12, 15, 0),
        end_time: DateTime.new(2022, 7, 4, 14, 30, 30)
      }

      run_command = -> { run_command(SetTimePromotionRange.new(**data)) }

      stream = "Pricing::TimePromotion$#{uid}"
      event = TimePromotionRangeSet.new(data: data)

      assert_events(stream, event) do
        run_command.call
      end
    end

    private

    def create_time_promotion(**kwargs)
      run_command(CreateTimePromotion.new(kwargs))
    end
  end
end
