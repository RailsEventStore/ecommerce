class DropCustomerColFromOrders < ActiveRecord::Migration[7.0]
  def change
    remove_column :orders, :customer
  end
end
