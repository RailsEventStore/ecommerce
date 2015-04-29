class CreateOrderLines < ActiveRecord::Migration
  def change
    create_table :order_lines do |t|
      t.string    :order_uid
      t.integer   :product_id
      t.string    :product_name
      t.integer   :quantity
    end
  end
end
