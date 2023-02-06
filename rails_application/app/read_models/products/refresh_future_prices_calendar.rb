module Products
  class RefreshFuturePricesCalendar < Infra::EventHandler
    def call(event)
      product_id = event.data.fetch(:product_id)
      ApplicationRecord.with_advisory_lock(Product, product_id) do
        product = Product.find_or_create_by(id: product_id)
        product.update!(current_prices_calendar: updated_prices_calendar(event, product))
      end
    end

    private

    def updated_prices_calendar(event, product)
        (product.read_attribute(:current_prices_calendar) << new_entry_from_event(event))
          .sort_by { |entry| Time.parse(entry[:valid_since]) }
    end

    def new_entry_from_event(event)
      {
        price: event.data.fetch(:price).to_s,
        valid_since: event.metadata.fetch(:valid_at).to_s
      }
    end
  end
end
