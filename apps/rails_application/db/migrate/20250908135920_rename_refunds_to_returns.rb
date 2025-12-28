class RenameRefundsToReturns < ActiveRecord::Migration[7.2]
  def change
    rename_table :refunds, :returns
    rename_table :refund_items, :return_items
    
    rename_column :return_items, :refund_uid, :return_uid
  end
end
