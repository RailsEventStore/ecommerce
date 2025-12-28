class AddVipToCustomer < ActiveRecord::Migration[6.1]
  def change
    add_column :customers, :vip, :boolean, default: false, null: false
  end
end
