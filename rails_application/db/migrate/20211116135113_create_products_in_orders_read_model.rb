class CreateProductsInOrdersReadModel < ActiveRecord::Migration[6.1]
  def change
    create_table :orders_products do |t|
      t.uuid    :uid, null: false
      t.string  :name
      t.decimal :price, precision: 8, scale: 2
    end
  end
end
