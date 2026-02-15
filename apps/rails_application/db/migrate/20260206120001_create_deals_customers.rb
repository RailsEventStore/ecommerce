class CreateDealsCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :deals_customers do |t|
      t.uuid :customer_id, null: false
      t.string :name
      t.timestamps
    end

    add_index :deals_customers, :customer_id, unique: true
  end
end
