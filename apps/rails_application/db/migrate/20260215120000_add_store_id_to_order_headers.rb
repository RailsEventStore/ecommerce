class AddStoreIdToOrderHeaders < ActiveRecord::Migration[7.1]
  def change
    add_column :order_headers, :store_id, :uuid
  end
end
