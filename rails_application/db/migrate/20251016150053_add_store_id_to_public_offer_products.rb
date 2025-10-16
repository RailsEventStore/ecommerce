class AddStoreIdToPublicOfferProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :public_offer_products, :store_id, :uuid
  end
end
