class CreateShipmentsProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :shipments_products do |t|
      t.uuid :uid, null: false
      t.string :name
    end
    add_index :shipments_products, :uid, unique: true
  end
end
