class CreateRefundItems < ActiveRecord::Migration[7.2]
  def change
    create_table :refund_items do |t|
      t.uuid :refund_uid
      t.uuid :product_uid
      t.integer :quantity
      t.decimal :price, precision: 8, scale: 2

      t.timestamps
    end
  end
end
