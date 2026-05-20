class CreateCustomersOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :customers_orders do |t|
      t.uuid :order_uid, null: false
      t.uuid :customer_id
      t.decimal :discounted_value, precision: 8, scale: 2

      t.timestamps
    end
    add_index :customers_orders, :order_uid, unique: true
  end
end
