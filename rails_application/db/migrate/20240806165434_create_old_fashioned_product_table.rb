class CreateOldFashionedProductTable < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.string :name
      t.decimal :price, precision: 10, scale: 2
      t.integer :vat_rate
      t.boolean :active, default: true
      t.string :sku
      t.string :description
      t.string :category

      t.timestamps
    end
  end
end
