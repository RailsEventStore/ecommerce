class AddPasswordHashToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :password_hash, :string
  end
end
