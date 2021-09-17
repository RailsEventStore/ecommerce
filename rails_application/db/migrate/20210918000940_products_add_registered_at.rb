class ProductsAddRegisteredAt < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :registered_at, :datetime
  end
end
