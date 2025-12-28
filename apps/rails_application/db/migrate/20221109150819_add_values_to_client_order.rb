class AddValuesToClientOrder < ActiveRecord::Migration[7.0]
  def change
    add_column "client_orders", "percentage_discount", :decimal, precision: 8, scale: 2
    add_column "client_orders", "total_value", :decimal, precision: 8, scale: 2
    add_column "client_orders", "discounted_value", :decimal, precision: 8, scale: 2
  end
end
