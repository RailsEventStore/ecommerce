module Orders
  class Order < ApplicationRecord
    self.table_name = "orders"

    has_many :order_lines,
             class_name: "Orders::OrderLine",
             foreign_key: :order_uid,
             primary_key: :uid

    def total_value
      order_lines.sum(&:value)
    end
  end
end
