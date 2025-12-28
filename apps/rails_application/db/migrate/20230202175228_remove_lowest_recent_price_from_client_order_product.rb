class RemoveLowestRecentPriceFromClientOrderProduct < ActiveRecord::Migration[7.0]
  def change
    remove_column :client_order_products, :lowest_recent_price, :decimal, precision: 8, scale: 2
  end
end
