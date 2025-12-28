class AddPriceToOrderLines < ActiveRecord::Migration[6.1]
  def change
    add_column :order_lines, :price, :decimal, precision: 8, scale: 2
  end
end
