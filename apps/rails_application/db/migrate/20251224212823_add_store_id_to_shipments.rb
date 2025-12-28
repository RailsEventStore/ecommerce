class AddStoreIdToShipments < ActiveRecord::Migration[8.0]
  def change
    add_column :shipments, :store_id, :uuid
  end
end
