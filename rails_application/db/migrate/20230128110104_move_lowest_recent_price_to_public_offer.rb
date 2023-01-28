class MoveLowestRecentPriceToPublicOffer < ActiveRecord::Migration[7.0]
  def up
    add_column :public_offer_products, :lowest_recent_price, :decimal, precision: 8, scale: 2

    execute <<~SQL
      UPDATE public_offer_products
      SET lowest_recent_price = client_order_products.lowest_recent_price
      FROM client_order_products
      WHERE client_order_products.uid = public_offer_products.id
    SQL
  end

  def down
    remove_column :public_offer_products, :lowest_recent_price
  end
end
