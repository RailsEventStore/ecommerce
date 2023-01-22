module ClientOrders
  class RegisterLowestPrice < Infra::EventHandler
    RECENT_PERIOD = 30.days

    def call(event)
      product_id = event.data.fetch(:product_id)

      link_to_stream(event, product_id)

      lowest_recent_price = lowest_recent_price_for(product_id)

      product = Product.find_by_uid(product_id)
      product.update!(lowest_recent_price: lowest_recent_price)
    end

    private

    def lowest_recent_price_for(product_id)
      price_changes = project_price_changes(product_id)
      border_event = find_border_event(price_changes)
      recent_events = price_changes.select { |price_change| recent_event?(price_change) }.push(border_event)

      recent_events.min_by { |price_change| price_change.fetch(:price) }.fetch(:price)
    end

    def project_price_changes(product_id)
      RailsEventStore::Projection
        .from_stream(stream_name(product_id))
        .init(-> { [] })
        .when(
          Pricing::PriceSet,
          ->(state, event) { state.push({ valid_at: event.valid_at, price: event.data.fetch(:price) }) }
        )
        .run(event_store)
        .sort_by { |price_change| price_change.fetch(:valid_at) }
    end

    def find_border_event(price_changes)
      first_in_scope_index = price_changes.find_index { |price_change| recent_event?(price_change) }
      index = [first_in_scope_index - 1, 0].max

      price_changes.fetch(index)
    end

    def recent_event?(price_change)
      valid_at = price_change.fetch(:valid_at)
      valid_at > RECENT_PERIOD.ago.beginning_of_day && valid_at < Time.now
    end

    def link_to_stream(event, product_id)
      Rails.configuration.event_store.link(
        event.event_id,
        stream_name: stream_name(product_id)
      )
    end

    def stream_name(product_id)
      "PricesHistoryReport$#{product_id}"
    end
  end
end
