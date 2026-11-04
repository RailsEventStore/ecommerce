class AddDiscountedLineValuesToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :discounted_line_values, :jsonb, default: {}, null: false
    add_column :client_orders, :discounted_line_values, :jsonb, default: {}, null: false
  end
end
