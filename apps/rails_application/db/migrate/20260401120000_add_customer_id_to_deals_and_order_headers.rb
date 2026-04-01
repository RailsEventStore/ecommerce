class AddCustomerIdToDealsAndOrderHeaders < ActiveRecord::Migration[7.1]
  def change
    add_column :deals, :customer_id, :uuid
    add_column :order_headers, :customer_id, :uuid
  end
end
