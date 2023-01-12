class AddLowestRecentPriceToClientOrderProducts < ActiveRecord::Migration[7.0]
  def up
    add_column :client_order_products, :lowest_recent_price, :decimal, precision: 8, scale: 2

    execute <<~SQL
      UPDATE client_order_products
      SET lowest_recent_price = price;
    SQL
  end

  def down
    remove_column :client_order_products, :lowest_recent_price
  end
end
