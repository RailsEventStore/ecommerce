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
      sorted = history.sort_by { |entry| entry.fetch(:valid_at) }
      border = sorted.reverse.find { |entry| !recent?(entry) }
      recent_prices = sorted.select { |entry| recent?(entry) && !future?(entry) }.map { |entry| BigDecimal(entry.fetch(:price)) }
      prices = border ? recent_prices + [BigDecimal(border.fetch(:price))] : recent_prices
      prices.min
    end

    def recent?(entry)
      entry.fetch(:valid_at) > RECENT_PERIOD.ago.beginning_of_day
    end

    def future?(entry)
      entry.fetch(:valid_at) > Time.now
    end
  end
end
