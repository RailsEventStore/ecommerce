class CreateActivities < ActiveRecord::Migration[7.2]
  def change
    create_table :activities do |t|
      t.string :entity_type, null: false
      t.uuid :entity_uid, null: false
      t.string :action, null: false
      t.datetime :occurred_at, null: false
      t.timestamps
    end

    add_index :activities, :occurred_at
  end
end
