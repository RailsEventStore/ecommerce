class AddOrderTotalValueUpdatedAtToOrdersTable < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :total_value_updated_at, :datetime
  end
end
