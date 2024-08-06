class CreateInvoices < ActiveRecord::Migration[7.0]
  def change
    create_table :invoices_tbl do |t|
      t.bigint :order_id
      t.string :order_number
      t.decimal :total_value, precision: 10, scale: 2
      t.string :address
      t.datetime :payment_date
      t.datetime :issued_at
      t.bigint :tax_id_number

      t.timestamps
    end
  end
end
