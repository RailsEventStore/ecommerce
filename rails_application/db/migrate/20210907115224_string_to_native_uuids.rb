class StringToNativeUuids < ActiveRecord::Migration[6.1]
  def change
    change_column :orders,       :uid,       :uuid, null: false, using: "uid::uuid"
    change_column :order_lines,  :order_uid, :uuid, null: false, using: "order_uid::uuid"
  end
end
