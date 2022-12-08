class RenameFuturePricesColumn < ActiveRecord::Migration[7.0]
  def change
    rename_column :products, :prices_chart, :future_prices_calendar
  end
end
