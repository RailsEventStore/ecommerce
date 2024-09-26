class CreateMostRecentProductsInUnfinishedOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :most_recent_products_in_unfinished_orders do |t|
      t.string :product_name, null: false
      t.integer :product_id, null: false, index: true
      t.integer :number_of_unfinished_orders, default: 0, null: false
      t.integer :number_of_items_in_unfinished_orders, default: 0, null: false
      t.integer :order_ids, array: true, default: [], null: false

      t.timestamps
    end
  end
end
