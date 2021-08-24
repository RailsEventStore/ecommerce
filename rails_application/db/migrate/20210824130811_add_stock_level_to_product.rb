class AddStockLevelToProduct < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :stock_level, :integer
  end
end
