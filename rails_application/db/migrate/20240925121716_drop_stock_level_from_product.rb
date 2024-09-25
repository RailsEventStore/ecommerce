class DropStockLevelFromProduct < ActiveRecord::Migration[7.0]
  def change
    remove_column :products, :stock_level
  end
end
