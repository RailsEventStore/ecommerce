class AddVersionColumnToProductsTable < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :version, :integer, default: 0
  end
end
