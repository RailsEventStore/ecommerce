class RemoveCodeColumnFromTimePromotions < ActiveRecord::Migration[7.0]
  def change
    remove_column :time_promotions, :code, :string
  end
end
