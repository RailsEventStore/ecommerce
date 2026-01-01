class CreateOrderHeaderCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :order_header_customers do |t|
      t.uuid :customer_id
      t.string :name

      t.timestamps
    end
    add_index :order_header_customers, :customer_id, unique: true
  end
end
