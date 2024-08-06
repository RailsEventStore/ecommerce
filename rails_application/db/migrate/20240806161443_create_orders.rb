class CreateOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :orders do |t|
      t.string :number
      t.string :customer
      t.string :address
      t.string :phone
      t.string :email
      t.string :status
      t.decimal :total, precision: 10, scale: 2
      t.decimal :discount, precision: 10, scale: 2
      t.datetime :completed_at
      t.datetime :discount_updated_at

      t.timestamps
    end
  end
end
