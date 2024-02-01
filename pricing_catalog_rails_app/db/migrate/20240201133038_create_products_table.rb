class CreateProductsTable < ActiveRecord::Migration[7.1]
  def change
    PublicCatalog::Migration.new.change
  end
end
