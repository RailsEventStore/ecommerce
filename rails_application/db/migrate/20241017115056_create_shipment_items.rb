class CreateShipmentItems < ActiveRecord::Migration[7.2]
  def change
    create_table :shipment_items do |t|
      t.references :shipment, null: false
      t.string :product_name, null: false
      t.integer :quantity, null: false
      t.uuid :product_id, null: false

      t.timestamps
    end
  end
end
