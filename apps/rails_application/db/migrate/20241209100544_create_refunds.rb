class CreateRefunds < ActiveRecord::Migration[7.2]
  def change
    create_table :refunds do |t|
      t.uuid :uid, null: false
      t.uuid :order_uid, null: false
      t.string :status, null: false
      t.decimal :total_value, precision: 8, scale: 2, null: false

      t.timestamps
    end
  end
end
