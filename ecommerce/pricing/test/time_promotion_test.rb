require_relative "test_helper"

require "timecop"

module Pricing
  class TimePromotionTest < Test
    cover "Pricing::TimePromotion*"

    def test_creates_time_promotion
      uid = SecureRandom.uuid
      start_time = Time.utc(2022, 7, 1, 12, 15, 0)
      end_time = Time.utc(2022, 7, 4, 14, 30, 30)
      discount = 25
      label = "Summer Sale"
      data = {
        time_promotion_id: uid,
        discount: discount,
        start_time: start_time,
        end_time: end_time,
        label: label
      }

      run_command = -> { create_time_promotion(**data) }

      stream = "Pricing::TimePromotion$#{uid}"
      event = TimePromotionCreated.new(data: data)

      assert_events(stream, event) do
        run_command.call
      end
    end

    private

    def create_time_promotion(**kwargs)
      run_command(CreateTimePromotion.new(kwargs))
    end
  end

  class DiscountWithTimePromotionTest < Test
    cover "Pricing::Offer*"

    def test_calculates_total_value_with_time_promotion
      order_id = SecureRandom.uuid
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      stream = stream_name(order_id)
      time_promotion_id = SecureRandom.uuid
      start_time = Time.current - 1
      end_time = Time.current + 1
      set_time_promotion_range(time_promotion_id, start_time, end_time, 50)

      run_command(SetTimePromotionDiscount.new(order_id: order_id, amount: 50))

      assert_events_contain(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_1_id,
            base_price: 20,
            price: 10
          }
        )
      ) { add_item(order_id, product_1_id) }
    end


    def test_cant_create_twice
      uid = SecureRandom.uuid
      start_time = Time.utc(2022, 7, 1, 12, 15, 0)
      end_time = Time.utc(2022, 7, 4, 14, 30, 30)
      discount = 25
      label = "Summer Sale"
      data = {
        time_promotion_id: uid,
        discount: discount,
        start_time: start_time,
        end_time: end_time,
        label: label
      }

      run_command(CreateTimePromotion.new(data))

      assert_raises(Pricing::TimePromotion::AlreadyCreated) do
        run_command(CreateTimePromotion.new(data))
      end
    end


    private

    def set_not_applicable_promotions(timestamp)
      time_promotion_id = SecureRandom.uuid
      start_time = timestamp - 2
      end_time = timestamp - 1
      set_time_promotion_range(time_promotion_id, start_time, end_time, 70)

      time_promotion_id = SecureRandom.uuid
      start_time = timestamp + 1
      end_time = timestamp + 2
      set_time_promotion_range(time_promotion_id, start_time, end_time, 80)

      time_promotion_id = SecureRandom.uuid
      start_time = timestamp - 1
      end_time = timestamp
      set_time_promotion_range(time_promotion_id, start_time, end_time, 90)
    end

    def stream_name(order_id)
      "Pricing::Offer$#{order_id}"
    end

    def set_time_promotion_range(time_promotion_id, start_time, end_time, discount)
      run_command(
        CreateTimePromotion.new(time_promotion_id: time_promotion_id, start_time: start_time, end_time: end_time, discount: discount, label: "test")
      )
    end

  end
end
