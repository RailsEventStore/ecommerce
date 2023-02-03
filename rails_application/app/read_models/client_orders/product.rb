module ClientOrders
  class Product < ApplicationRecord
    self.table_name = "client_order_products"
  end
end
