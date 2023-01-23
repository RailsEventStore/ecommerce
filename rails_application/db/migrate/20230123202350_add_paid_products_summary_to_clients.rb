class AddPaidProductsSummaryToClients < ActiveRecord::Migration[7.0]
  def change
    add_column :clients, :paid_orders_summary, :decimal, precision: 8, scale: 2, default: 0
  end
end
