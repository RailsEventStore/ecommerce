class CreateClientOrderLinesReadModel < ActiveRecord::Migration[7.0]
  def up
    create_table :client_order_lines do |t|
      t.string    :order_uid
      t.integer   :product_id
      t.string    :product_name
      t.integer   :product_quantity
      t.decimal   :product_price, precision: 8, scale: 2
    end
  end

  def down
    drop_table :client_order_lines
  end
end
