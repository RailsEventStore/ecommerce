class AddActiveToTimePromotions < ActiveRecord::Migration[7.0]
  def change
    add_column :time_promotions, :active, :boolean, default: false
  end
end
