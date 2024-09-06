module Pricing
  class PromotionsCalendar
    def initialize(event_store)
      @event_store = event_store
    end

    def current_time_promotions_discount
      Discounts::Discount.build(
        PromotionsStrategy.biggest_for_client(all_promotions)
      )
    end

    private

    def all_promotions
      @event_store
        .read
        .of_type(TimePromotionCreated)
        .map { |e| Promotion.from_event(e) }
    end

    class PromotionsStrategy
      def self.biggest_for_client(promotions)
        promotions
          .filter { |promotion| promotion.running?(Time.current) }
          .map { |promotion| promotion.discount }.max || 0
      end
    end

    class Promotion
      attr_accessor :discount

      def self.from_event(event)
        new(
          event.data.fetch(:start_time),
          event.data.fetch(:end_time),
          event.data.fetch(:discount)
        )
      end

      def initialize(start_time, end_time, discount)
        @start_time = start_time
        @end_time = end_time
        @discount = discount
      end

      def running?(timestamp)
        (@start_time...@end_time).cover?(timestamp)
      end
    end
  end
end
