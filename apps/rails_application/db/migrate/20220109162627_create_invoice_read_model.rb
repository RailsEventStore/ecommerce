class CreateInvoiceReadModel < ActiveRecord::Migration[6.1]
  def change
    create_table :invoices do |t|
      t.string :order_uid, null: false
      t.string :number
      t.string :tax_id_number
      t.string :address_line_1
      t.string :address_line_2
      t.string :address_line_3
      t.string :address_line_4
      t.boolean :address_present, default: false
      t.boolean :issued, default: false
      t.date :issue_date
      t.date :disposal_date
      t.date :payment_date
      t.decimal :total_value, precision: 8, scale: 2
    end

    create_table :invoice_items do |t|
      t.references :invoice
      t.string :name
      t.decimal :unit_price, precision: 8, scale: 2
      t.decimal :vat_rate, precision: 4, scale: 1
      t.integer :quantity
      t.decimal :value, precision: 8, scale: 2
    end
  end
end
