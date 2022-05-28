class CreateHappyHours < ActiveRecord::Migration[7.0]
  def change
    create_table :happy_hours do |t|
      t.uuid :uid, null: false
      t.string :name
      t.string :code
      t.integer :discount
      t.integer :start_hour
      t.integer :end_hour
      t.string :product_ids, array: true

      t.timestamps
    end

    add_index :happy_hours, :uid, unique: true
  end
end
