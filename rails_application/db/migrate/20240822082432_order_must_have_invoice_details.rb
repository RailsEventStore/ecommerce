class OrderMustHaveInvoiceDetails < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :invoice_address, :string
    add_column :orders, :invoice_tax_id_number, :string
    add_column :orders, :invoice_issued, :boolean, default: false
    add_column :orders, :invoice_issue_date, :date
    add_column :orders, :invoice_disposal_date, :date
    add_column :orders, :invoice_payment_date, :date
    add_column :orders, :invoice_total_value, :decimal, precision: 8, scale: 2
    add_column :orders, :invoice_country, :string
    add_column :orders, :invoice_city, :string
    add_column :orders, :invoice_addressed_to, :string
  end
end
