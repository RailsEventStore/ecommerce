class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.uuid :account_id, null: false
      t.string :handle
      t.timestamps
    end
    add_index :accounts, :account_id, unique: true
  end
end
