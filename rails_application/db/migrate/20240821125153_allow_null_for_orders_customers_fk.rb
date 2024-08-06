class AllowNullForOrdersCustomersFk < ActiveRecord::Migration[7.0]
  def change
    change_column :orders, :customer_id, :integer, null: true
  end
end
