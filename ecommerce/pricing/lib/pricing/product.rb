module Pricing
  class Product
    include AggregateRoot

    OverlappingHappyHour = Class.new(StandardError)

    attr_reader :happy_hours_schedule

    def initialize(id)
      @id = id
      @happy_hours_schedule = HappyHoursSchedule.new({})
    end

    def set_price(price)
      apply(PriceSet.new(data: { product_id: @id, price: price }))
    end

    def add_product_to_happy_hour(discount, start_hour, end_hour)
      apply(
        ProductAddedToHappyHour.new(
          data: {
            product_id: @id,
            discount: discount,
            start_hour: start_hour,
            end_hour: end_hour
          }
        )
      )
    end

    private

    on(PriceSet) { |_| }

    on ProductAddedToHappyHour do |event|
      @happy_hours_schedule = happy_hours_schedule.add(
        event.data[:discount],
        event.data[:start_hour],
        event.data[:end_hour]
      )
    end

    class HappyHoursSchedule
      attr_reader :schedule

      def initialize(schedule)
        @schedule = schedule
      end

      def add(discount, start_hour, end_hour)
        new_schedule = create_schedule_from(discount, start_hour, end_hour)

        raise OverlappingHappyHour if overlapping_hours?(new_schedule)

        HappyHoursSchedule.new(schedule.merge(new_schedule))
      end

      private

      def overlapping_hours?(new_schedule)
        (schedule.keys & new_schedule.keys).any?
      end

      def create_schedule_from(discount, start_hour, end_hour)
        if start_hour >= end_hour
          first_segment = hours_range_with_discount(Range.new(0, end_hour - 1), discount)
          second_segment = hours_range_with_discount(Range.new(start_hour, 23), discount)

          first_segment.merge(second_segment)
        else
          hours_range_with_discount(Range.new(start_hour, end_hour - 1), discount)
        end
      end

      def hours_range_with_discount(range, discount)
        range.to_h { |hour| [hour, discount] }
      end
    end
  end
end
