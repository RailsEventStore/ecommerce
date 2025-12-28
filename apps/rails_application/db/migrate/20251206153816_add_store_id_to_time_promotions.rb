class AddStoreIdToTimePromotions < ActiveRecord::Migration[8.0]
  def change
    add_column :time_promotions, :store_id, :uuid
  end
end
