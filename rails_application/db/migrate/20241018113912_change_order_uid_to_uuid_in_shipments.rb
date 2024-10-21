class ChangeOrderUidToUuidInShipments < ActiveRecord::Migration[7.2]
  def up
    change_column :shipments, :order_uid, 'uuid USING order_uid::uuid', null: false
  end

  def down
    change_column :shipments, :order_uid, 'varchar USING order_uid::varchar', null: false
  end
end
