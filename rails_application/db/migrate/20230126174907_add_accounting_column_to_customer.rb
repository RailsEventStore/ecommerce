class AddAccountingColumnToCustomer < ActiveRecord::Migration[7.0]
  def change
    add_column :customers, :account_id, :uuid
  end
end
