require_relative "test_helper"

module Pricing
  class HappyHourTest < Test
    cover "Pricing::HappyHour*"

    def setup
      @uid = SecureRandom.uuid
      @code = fake_name.chars.shuffle.join
      @discount = 20
      @start_hour = 13
      @end_hour = 18
      @data = {
        id: @uid,
        details: {
          name: fake_name,
          code: @code,
          discount: @discount,
          start_hour: @start_hour,
          end_hour: @end_hour
        }
      }
      @stream = "Pricing::HappyHour$#{@uid}"
      @event = HappyHourCreated.new(data: @data)
    end

    def test_happy_hour_is_created
      assert_events(@stream, @event) do
        create_happy_hour(**@data)
      end
    end

    def test_should_not_allow_for_id_based_duplicates
      assert_raises(Pricing::HappyHour::AlreadyCreated) do
        create_happy_hour(**@data)
        create_happy_hour(**@data)
      end
    end

    private

    def create_happy_hour(**kwargs)
      run_command(
        CreateHappyHour.new(kwargs)
      )
    end
  end
end
