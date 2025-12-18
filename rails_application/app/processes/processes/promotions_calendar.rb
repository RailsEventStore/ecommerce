module Processes
  class PromotionsCalendar
    def initialize(event_store, store_id)
      @event_store = event_store
      @store_id = store_id
    end

    def current_time_promotions_discount(timestamp = Time.current)
      Pricing::Discounts::Discount.build(
        PromotionsStrategy.biggest_for_client(all_promotions, timestamp)
      )
    end

    private

    def all_promotions
      @event_store
        .read
        .stream("Stores::Store$#{@store_id}")
        .of_type(Stores::TimePromotionRegistered)
        .map { |e| load_promotion_from_registration(e) }
        .compact
    end

    def load_promotion_from_registration(event)
      time_promotion_id = event.data.fetch(:time_promotion_id)
      created_event = @event_store
        .read
        .stream("Pricing::TimePromotion$#{time_promotion_id}")
        .of_type(Pricing::TimePromotionCreated)
        .first

      Promotion.from_event(created_event) if created_event
    end

    class PromotionsStrategy
      def self.biggest_for_client(promotions, timestamp)
        promotions
          .filter { |promotion| promotion.running?(timestamp) }
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
