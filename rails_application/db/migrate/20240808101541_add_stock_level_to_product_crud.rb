class AddStockLevelToProductCrud < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :stock_level, :integer
  end
end
