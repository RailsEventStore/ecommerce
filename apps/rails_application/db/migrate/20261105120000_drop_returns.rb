class DropReturns < ActiveRecord::Migration[8.1]
  def change
    drop_table :return_items
    drop_table :returns
    drop_table :returns_products
  end
end
