class AddDiscountAndTotalValueAndDiscountValueToOrders < ActiveRecord::Migration[6.1]
  def change
    add_column "orders", "percentage_discount", :decimal, precision: 8, scale: 2
    add_column "orders", "total_value", :decimal, precision: 8, scale: 2
    add_column "orders", "discounted_value", :decimal, precision: 8, scale: 2
  end
end
