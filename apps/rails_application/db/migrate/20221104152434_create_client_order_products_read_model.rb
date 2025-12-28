class CreateClientOrderProductsReadModel < ActiveRecord::Migration[7.0]
  def change
    create_table :client_order_products do |t|
      t.uuid    "uid", null: false
      t.string  "name"
      t.decimal "price", precision: 8, scale: 2
    end
  end
end
