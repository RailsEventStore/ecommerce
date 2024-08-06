class RenameUserToCustomer < ActiveRecord::Migration[7.0]
  def change
    rename_table :users, :customers
  end
end
