class AddTimePromotionDiscountToClientOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :client_orders, :time_promotion_discount, :jsonb
  end
end
