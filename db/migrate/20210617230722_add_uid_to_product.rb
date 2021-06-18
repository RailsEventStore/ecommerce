class AddUidToProduct < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :uid, :uuid
  end
end