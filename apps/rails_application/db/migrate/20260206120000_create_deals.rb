class CreateDeals < ActiveRecord::Migration[8.0]
  def change
    create_table :deals do |t|
      t.uuid :uid, null: false
      t.string :order_number
      t.string :customer_name
      t.string :stage, null: false, default: "Draft"
      t.decimal :value, precision: 8, scale: 2
      t.uuid :store_id
      t.timestamps
    end

    add_index :deals, :uid, unique: true
  end
end
