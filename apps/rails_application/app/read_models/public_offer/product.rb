module PublicOffer
  class Product < ApplicationRecord
    self.table_name = "public_offer_products"

    def lowest_recent_price_lower_from_current?
      lowest_recent_price && lowest_recent_price < price
    end
  end
end
