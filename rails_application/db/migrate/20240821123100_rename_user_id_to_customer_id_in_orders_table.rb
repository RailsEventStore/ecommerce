class RenameUserIdToCustomerIdInOrdersTable < ActiveRecord::Migration[7.0]
  def change
    rename_column :orders, :user_id, :customer_id
  end
end
