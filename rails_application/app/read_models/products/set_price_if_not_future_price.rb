module Products
  class SetPriceIfNotFuturePrice
    def call(event)
      return if event.metadata.fetch(:valid_at) > Time.now

      product_id = event.data.fetch(:product_id)
      product = Product.find(product_id)
      product.update!(price: event.data.fetch(:price))
    end
  end
end
