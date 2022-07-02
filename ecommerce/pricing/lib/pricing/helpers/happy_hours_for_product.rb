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

        combined_schedule.select { |hour, _| new_happy_hour.include?(hour) }.values.flatten.uniq
      end

      private

      def product_happy_hours(product_id)
        events = @event_store.read.stream("Pricing::Product$#{product_id}").of_type(ProductAddedToHappyHour).to_a

        product = Product.new(product_id)

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
            combined_schedule[hour] << product_id
          end
        end

        combined_schedule
      end

      def build_happy_hour(start_hour, end_hour)
        if start_hour >= end_hour
          first_segment = Range.new(0, end_hour - 1).to_a
          second_segment = Range.new(start_hour, 23).to_a

          first_segment.union(second_segment)
        else
          Range.new(start_hour, end_hour - 1).to_a
        end
      end
    end
  end
end
