class MigrateFromIdToUuid < ActiveRecord::Migration[6.1]
  def change
    change_table :products do |t|
      t.remove :id
      t.change_default :uid, "gen_random_uuid()"
      t.change_null :uid, false
      t.rename :uid, :id
    end
    execute "ALTER TABLE products ADD PRIMARY KEY (id);"

    change_table :customers do |t|
      t.remove :id
      t.change_default :uid, "gen_random_uuid()"
      t.change_null :uid, false
      t.rename :uid, :id
    end
    execute "ALTER TABLE customers ADD PRIMARY KEY (id);"

    remove_column :order_lines, :product_id
    add_column :order_lines, :product_id, :uuid
  end
end
