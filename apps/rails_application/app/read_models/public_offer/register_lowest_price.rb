module PublicOffer
  class RegisterLowestPrice
    RECENT_PERIOD = 30.days

    def call(event)
      product = Product.find(event.data.fetch(:product_id))
      product.price_history = product.price_history + [new_entry(event)]
      product.lowest_recent_price = lowest_recent(product.price_history)
      product.save!
    end

    private

    def new_entry(event)
      { valid_at: event.valid_at.utc.iso8601, price: event.data.fetch(:price).to_s }
    end

    def lowest_recent(history)
      recent_prices(history).min
    end

    def recent_prices(history)
      (recent_entries(history) + [border_entry(history)].compact).map { |entry| price_of(entry) }
    end

    def recent_entries(history)
      history.select { |entry| recent?(entry) && !future?(entry) }
    end

    def border_entry(history)
      history.sort_by { |entry| valid_at_of(entry) }.reverse.find { |entry| !recent?(entry) }
    end

    def price_of(entry)
      BigDecimal(entry.fetch(:price))
    end

    def valid_at_of(entry)
      entry.fetch(:valid_at)
    end

    def recent?(entry)
      valid_at_of(entry) > RECENT_PERIOD.ago.beginning_of_day
    end

    def future?(entry)
      valid_at_of(entry) > Time.now
    end
  end
end
