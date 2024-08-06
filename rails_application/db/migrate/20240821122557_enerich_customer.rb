class EnerichCustomer < ActiveRecord::Migration[7.0]
  def change
    add_column :customers, :vip, :boolean, default: false
  end
end
