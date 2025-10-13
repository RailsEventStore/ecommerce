class CreateAdminStores < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_stores, id: false do |t|
      t.uuid :id, primary_key: true
      t.string :name
      t.timestamps
    end
  end
end
