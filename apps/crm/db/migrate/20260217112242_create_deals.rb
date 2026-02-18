class CreateDeals < ActiveRecord::Migration[8.0]
  def change
    create_table :deals do |t|
      t.uuid :uid, null: false
      t.uuid :pipeline_uid, null: false
      t.string :name, null: false
      t.integer :value
      t.string :expected_close_date
      t.string :stage

      t.timestamps
    end
    add_index :deals, :uid, unique: true
  end
end
