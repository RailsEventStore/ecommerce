# frozen_string_literal: true

ROM::SQL.migration do
  up do
    create_table :products do
      column :id, String, size: 36, primary_key: true
      column :name, String
      column :price, BigDecimal
    end

    create_table :orders do
      column :id, String, size: 36, primary_key: true
      column :state, String, null: false
      column :number, String
    end

    create_table :order_lines do
      primary_key :id, type: :Bignum, null: false

      column :order_id, String, size: 36, null: false
      column :product_id, String, size: 36, null: false
      column :price, BigDecimal, null: false
      column :quantity, Integer, null: false

      index %i[order_id product_id], unique: true, name: "index_order_lines_on_order_id_and_product_id"
    end
  end

  down do
    drop_table :order_lines
    drop_table :orders
    drop_table :products
  end
end
