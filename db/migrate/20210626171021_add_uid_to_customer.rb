class AddUidToCustomer < ActiveRecord::Migration[6.1]
  def change
    add_column :customers, :uid, :uuid
  end
end
