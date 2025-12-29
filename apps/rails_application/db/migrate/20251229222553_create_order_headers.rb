class CreateOrderHeaders < ActiveRecord::Migration[8.0]
  def change
    create_table :order_headers do |t|
      t.uuid :uid, null: false, index: { unique: true }
      t.string :number
      t.string :customer
      t.string :state, null: false
      t.boolean :shipping_address_present, default: false
      t.boolean :billing_address_present, default: false
      t.boolean :invoice_issued, default: false
      t.string :invoice_number

      t.timestamps
    end
  end
end
