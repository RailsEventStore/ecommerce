class RemoveHeaderFieldsFromOrders < ActiveRecord::Migration[8.0]
  def change
    remove_column :orders, :number, :string
    remove_column :orders, :customer, :string
    remove_column :orders, :state, :string
  end
end
