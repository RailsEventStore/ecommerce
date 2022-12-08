module Products
  class UpdateFuturePricesCalendar < Infra::EventHandler
    def call(event)
      product = Product.find(event.data.fetch(:product_id))
      product.update!(future_prices_calendar: updated_prices_by_date(event, product.future_prices_calendar))
    end

    private

    def updated_prices_by_date(event, prices_calendar)
      (prices_calendar << event_to_entry(event)).sort_by { |pc| pc[:valid_since].to_datetime }
    end

    def event_to_entry(event)
      {
        valid_since: event.data.fetch(:valid_since).to_s,
        price: event.data.fetch(:price).to_s
      }
    end
  end
end
