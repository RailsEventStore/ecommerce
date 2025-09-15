class AddArchivedToOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :archived, :boolean, default: false, null: false
  end
end
