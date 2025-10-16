class AddStoreIdToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :store_id, :uuid
  end
end
