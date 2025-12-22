class AddStoreIdToCoupons < ActiveRecord::Migration[8.0]
  def change
    add_column :coupons, :store_id, :uuid
  end
end
