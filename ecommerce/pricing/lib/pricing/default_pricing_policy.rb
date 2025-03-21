module Pricing
  class DefaultPricingPolicy
    def initialize(pricing_catalog)
      @pricing_catalog = pricing_catalog
      @discounts = []
    end

    def apply(items, add_product_id = nil)
      ret = items.map do |item|
        Offer::ItemPrice.new(
          item.product_id,
          item.catalog_price,
          apply_discounts(item.catalog_price)
        )
      end
      ret << Offer::ItemPrice.new(
        add_product_id,
        catalog_price_for(add_product_id),
        apply_discounts(catalog_price_for(add_product_id))
      ) if add_product_id
      ret
    end

    def add_discount(discount)
      @discounts << discount
    end

    private

    def catalog_price_for(product_id)
      @pricing_catalog.price_by_product_id(product_id)
    end

    def apply_discounts(price)
      @discounts.inject(Discounts::NoPercentageDiscount.new, :add).apply(price)
    end
  end
end
