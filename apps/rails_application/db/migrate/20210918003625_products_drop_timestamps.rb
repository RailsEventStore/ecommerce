class ProductsDropTimestamps < ActiveRecord::Migration[6.1]
  def change
    remove_column :products, :created_at
    remove_column :products, :updated_at
  end
end
