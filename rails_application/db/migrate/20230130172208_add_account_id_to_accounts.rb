class AddAccountIdToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :account_id, :uuid
  end
end
