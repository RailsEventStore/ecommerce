class AddLoginToCustomers < ActiveRecord::Migration[7.2]
  def change
    add_column :customers, :login, :string
  end
end
