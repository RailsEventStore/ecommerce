module Orders
  class Order < ApplicationRecord
    self.table_name = "orders"

    has_many :order_lines,
             -> { order(id: :asc) },
             class_name: "Orders::OrderLine",
             foreign_key: :order_uid,
             primary_key: :uid

    def total_value
      if percentage_discount?
        value_before_discounts - (value_before_discounts * percentage_discount / 100.00)
      else
        value_before_discounts
      end
    end

    private

    def value_before_discounts
      order_lines.sum(&:value)
    end
  end
end
