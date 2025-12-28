class CreateTableAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :table_accounts do |t|
      t.uuid :client_id
      t.text :password
    end
  end
end
