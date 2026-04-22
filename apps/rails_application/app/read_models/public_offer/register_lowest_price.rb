module PublicOffer
  class RegisterLowestPrice
    RECENT_PERIOD = 30.days

    def call(event)
      product_id = event.data.fetch(:product_id)

      link_to_stream(event, product_id)

      lowest_recent_price = lowest_recent_price_for(product_id)

      product = Product.find(product_id)
      product.update!(lowest_recent_price: lowest_recent_price)
    end

    private

    def lowest_recent_price_for(product_id)
      price_changes = project_price_changes(product_id)
      recent_prices = price_changes.select { |pc| recent_event?(pc) && !future_event?(pc) }.map { |pc| pc.fetch(:price) }
      border_event = find_border_event(price_changes)
      prices = border_event ? recent_prices + [border_event.fetch(:price)] : recent_prices
      prices.min
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
      price_changes.reverse.find { |price_change| !recent_event?(price_change) }
    end

    def recent_event?(price_change)
      price_change.fetch(:valid_at) > RECENT_PERIOD.ago.beginning_of_day
    end

    def future_event?(price_change)
      price_change.fetch(:valid_at) > Time.now
    end

    def link_to_stream(event, product_id)
      event_store.link(event.event_id, stream_name: stream_name(product_id))
    rescue RubyEventStore::EventDuplicatedInStream
    end

    def event_store
      Rails.configuration.event_store
    end

    def stream_name(product_id)
      "PricesHistoryReport$#{product_id}"
    end
  end
end
