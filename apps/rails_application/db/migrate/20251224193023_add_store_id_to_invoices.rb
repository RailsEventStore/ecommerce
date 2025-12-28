class AddStoreIdToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :store_id, :uuid
  end
end
