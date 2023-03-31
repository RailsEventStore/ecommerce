module Pricing
  class PromotionsCalendar
    def initialize(event_store)
      @event_store = event_store
    end

    def current_time_promotions_discount
      Discounts::Discount.build(
        get_events(TimePromotionCreated)
        .filter { |e| current_promotions.include?(e.data.fetch(:time_promotion_id)) }
        .map { |e| e.data.fetch(:discount) }.sum
      )
    end

    private

    def current_promotions
      get_events(TimePromotionCreated)
        .filter { |e| is_promotion_running?(e) }
        .map { |e| e.data.fetch(:time_promotion_id) }
    end

    def is_promotion_running?(event)
      timestamp = Time.current
      start_time = event.data.fetch(:start_time)
      end_time = event.data.fetch(:end_time)

      timestamp >= start_time && end_time > timestamp
    end

    def get_events(event_type)
      @event_store
        .read
        .of_type(event_type)
        .to_a
        .group_by { |e| e.data.fetch(:time_promotion_id) }
        .map { |_, events| events.max_by(&:timestamp) }
    end
  end
end
