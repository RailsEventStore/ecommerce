class AddFuturePriceToProduct < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :future_price, :decimal, precision: 8, scale: 2
    add_column :products, :future_price_start_time, :datetime
  end
end
