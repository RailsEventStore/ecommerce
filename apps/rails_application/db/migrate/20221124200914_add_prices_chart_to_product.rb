class AddPricesChartToProduct < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :prices_chart, :text
  end
end
