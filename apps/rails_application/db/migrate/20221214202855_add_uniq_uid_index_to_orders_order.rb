class AddUniqUidIndexToOrdersOrder < ActiveRecord::Migration[7.0]
  def change
    add_index "orders", :uid, unique: true
  end
end
