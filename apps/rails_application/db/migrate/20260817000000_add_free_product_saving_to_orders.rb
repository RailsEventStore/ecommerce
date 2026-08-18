class AddFreeProductSavingToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :free_product_id, :uuid
    add_column :orders, :free_product_saving, :decimal, precision: 8, scale: 2, default: 0, null: false
  end
end
