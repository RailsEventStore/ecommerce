class DropOrder < ActiveRecord::Migration[7.0]
  def change
    drop_table :orders
  end
end
