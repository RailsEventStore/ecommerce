module ClientOrders
  class Product < ApplicationRecord
    self.table_name = "client_order_products"

    def lowest_recent_price_lower_from_current?
      lowest_recent_price < price
    end
  end
end
