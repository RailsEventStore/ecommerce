class RenameHappyHourValueToTimePromotionDiscountValue < ActiveRecord::Migration[7.2]
  def change
    rename_column :orders, :happy_hour_value, :time_promotion_discount_value
  end
end
