class AddInvoicePaidToOrder < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :invoice_payment_status, :string, default: "Unpaid"
  end
end
