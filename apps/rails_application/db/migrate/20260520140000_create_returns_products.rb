class CreateReturnsProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :returns_products do |t|
      t.uuid :uid, null: false
      t.decimal :price, precision: 8, scale: 2
    end
    add_index :returns_products, :uid, unique: true
  end
end
