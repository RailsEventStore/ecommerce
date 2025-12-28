class AddDiscountUpdatedAtToOrdersTable < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :discount_updated_at, :datetime
  end
end
