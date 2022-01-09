class CreateOrdersInInvoicesReadModel < ActiveRecord::Migration[6.1]
  def change
    create_table :invoices_orders do |t|
      t.uuid "uid", null: false
      t.boolean "submitted", default: false
    end
  end
end
