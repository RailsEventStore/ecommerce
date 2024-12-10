class CreateRefunds < ActiveRecord::Migration[7.2]
  def change
    create_table :refunds do |t|
      t.uuid :uid
      t.uuid :order_uid
      t.string :status
      t.decimal :total_value, precision: 8, scale: 2

      t.timestamps
    end
  end
end
