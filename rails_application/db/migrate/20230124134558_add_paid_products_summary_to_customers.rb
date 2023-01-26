class AddPaidProductsSummaryToCustomers < ActiveRecord::Migration[7.0]
  def change
    add_column :customers, :paid_orders_summary, :decimal, precision: 8, scale: 2, default: 0
  end
end
