class CreateProductCatalogs < ActiveRecord::Migration[7.0]
  def change
    create_table :product_catalogs do |t|
      t.string :checkpoint
      t.integer :product_id
      t.integer :stock_level

      t.timestamps
    end
  end
end
