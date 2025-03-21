class AddCatalogPriceToOrderReadModels < ActiveRecord::Migration[7.2]
  def change
    add_column :order_lines, :catalog_price, :decimal, precision: 8, scale: 2
    add_column :client_order_lines, :catalog_price, :decimal, precision: 8, scale: 2
  end
end
