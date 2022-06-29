module Pricing
  module Helpers
    class HappyHoursForProduct
      def initialize(event_store)
        @event_store = event_store
      end

      def discount_for(product_id, hour)
        product = product_happy_hours(product_id)

        product.happy_hours_schedule.schedule.fetch(hour, nil)
      end

      def products_with_overlapping_happy_hours(product_ids, start_hour, end_hour)
        combined_schedule = build_combined_schedule(product_ids)
        new_happy_hour = build_happy_hour(start_hour, end_hour)

        combined_schedule.select { |hour,| new_happy_hour.include?(hour) }.values.flatten.uniq
      end

      private

      def product_happy_hours(product_id)
        events = @event_store.read.stream("Pricing::Product$#{product_id}")
        product = Product.new

        product.apply(*events)

        product
      end

      def build_combined_schedule(product_ids)
        combined_schedule = {}

        product_ids.each do |product_id|
          product = product_happy_hours(product_id)
          schedule = product.happy_hours_schedule.schedule

          schedule.keys.each do |hour|
            combined_schedule[hour] ||= []
            combined_schedule.fetch(hour) << product_id
          end
        end

        combined_schedule
      end

      def build_happy_hour(start_hour, end_hour)
        if start_hour >= end_hour
          first_segment = Range.new(0, end_hour - 1).to_a
          second_segment = Range.new(start_hour, 23).to_a

          validate_hours_list(first_segment)
          validate_hours_list(second_segment)

          first_segment.union(second_segment)
        else
          Range.new(start_hour, end_hour - 1)
        end
      end

      def validate_hours_list(sorted_hours)
        return if sorted_hours.empty?

        Infra::Types::Hour[sorted_hours.first]
        Infra::Types::Hour[sorted_hours.last]
      end
    end
  end
end
