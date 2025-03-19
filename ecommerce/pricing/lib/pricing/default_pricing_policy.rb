module Pricing
  class DefaultPricingPolicy
    def initialize(pricing_catalog)
      @pricing_catalog = pricing_catalog
      @discounts = []
    end

    def apply(items, add_product_id = nil)
      items
      items += [catalog_price_for(add_product_id)] if add_product_id
      items.map { |item| apply_discounts(item) }
    end

    def add_discount(discount)
      @discounts << discount
      self
    end

    private

    def catalog_price_for(product_id)
      price = @pricing_catalog.price_by_product_id(product_id)
      Offer::ItemPrice.new(product_id, price, price)
    end

    def apply_discounts(item)
      price = @discounts.inject(Discounts::NoPercentageDiscount.new, :add).apply(item.catalog_price)
      Offer::ItemPrice.new(item.product_id, item.catalog_price, price)
    end
  end
end
