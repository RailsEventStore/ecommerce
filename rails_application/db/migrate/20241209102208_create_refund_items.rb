class CreateRefundItems < ActiveRecord::Migration[7.2]
  def change
    create_table :refund_items do |t|
      t.uuid :refund_uid, null: false
      t.uuid :product_uid, null: false
      t.integer :quantity, null: false
      t.decimal :price, precision: 8, scale: 2, null: false

      t.timestamps
    end
  end
end
