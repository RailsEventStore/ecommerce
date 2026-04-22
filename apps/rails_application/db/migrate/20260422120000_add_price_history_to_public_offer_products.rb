class AddPriceHistoryToPublicOfferProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :public_offer_products, :price_history, :text
  end
end
