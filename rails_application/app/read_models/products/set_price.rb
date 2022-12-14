module Products
  class SetPrice < Infra::EventHandler
    def call(event)
      product_id = event.data.fetch(:product_id)
      price = event.data.fetch(:price)
      product = Product.find(product_id)
      product.update!(price: price_for(product_id))
    end

    private

    def price_for(product_id)
      Pricing::PricingCatalog
        .new(event_store)
        .price_by_product_id(product_id)
    end
  end
end
