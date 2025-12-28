class AddHappyHourValueToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :happy_hour_value, :decimal, precision: 8, scale: 2
  end
end
