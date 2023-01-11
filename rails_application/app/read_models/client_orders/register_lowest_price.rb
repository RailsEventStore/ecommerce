module ClientOrders
  class RegisterLowestPrice < Infra::EventHandler
    def call(event)
      product_id = event.data.fetch(:product_id)
      product = Product.find_by_uid(product_id)

      product.update!(lowest_recent_price: lowest_recent_price_for(product_id))
    end

    private

    def lowest_recent_price_for(product_id)
      Pricing::PricingCatalog
        .new(event_store)
        .lowest_recent_price_by_product_id(product_id)
    end
  end
end
