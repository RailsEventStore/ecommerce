class AddUniqueConstraintOnCodeOnTimePromotions < ActiveRecord::Migration[7.0]
  def change
    add_index :time_promotions, :code, unique: true
  end
end
