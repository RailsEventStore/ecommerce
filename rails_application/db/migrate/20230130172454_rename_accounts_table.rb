class RenameAccountsTable < ActiveRecord::Migration[7.0]
  def change
    rename_table :table_accounts, :accounts
  end
end
