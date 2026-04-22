module PublicOffer
  class Product < ApplicationRecord
    self.table_name = "public_offer_products"
    serialize :price_history, type: Array, coder: YAML

    def lowest_recent_price_lower_from_current?
      lowest_recent_price && lowest_recent_price < price
    end
  end

  private_constant :Product

  def self.find_product(product_id)
    Product.find(product_id)
  end

  def self.products_in_store(store_id)
    Product.where(store_id: store_id)
  end
end
