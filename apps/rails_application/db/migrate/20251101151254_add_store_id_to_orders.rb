class AddStoreIdToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :store_id, :uuid
  end
end
