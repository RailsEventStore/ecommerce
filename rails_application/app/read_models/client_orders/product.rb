module ClientOrders
  class Product < ApplicationRecord
    self.table_name = "client_order_products"

    self.ignored_columns = ["lowest_recent_price"]
  end
end
