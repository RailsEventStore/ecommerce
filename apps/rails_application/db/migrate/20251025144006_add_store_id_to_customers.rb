class AddStoreIdToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :store_id, :uuid
  end
end
