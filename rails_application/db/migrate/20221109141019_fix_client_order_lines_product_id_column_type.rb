class FixClientOrderLinesProductIdColumnType < ActiveRecord::Migration[7.0]
  def change
    remove_column :client_order_lines, :product_id, :integer
    add_column :client_order_lines, :product_id, :uuid
  end
end
