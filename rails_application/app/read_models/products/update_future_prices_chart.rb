module Products
  class UpdateFuturePricesChart < Infra::EventHandler
    def call(event)
      product = Product.find(event.data.fetch(:product_id))
      product.update!(prices_chart: product.prices_chart << future_price_from(event))
    end

    private

    def future_price_from(event)
      {
        valid_at: event.data.fetch(:valid_at),
        price: event.data.fetch(:price)
      }
    end
  end
end
