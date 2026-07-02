class CreateHomeTimeline < ActiveRecord::Migration[8.1]
  def change
    create_table :home_timeline_edges do |t|
      t.uuid :follower_id, null: false
      t.uuid :followee_id, null: false
      t.timestamps
    end
    add_index :home_timeline_edges, :followee_id

    create_table :home_timeline_entries do |t|
      t.uuid :recipient_id, null: false
      t.string :author, null: false
      t.text :body, null: false
      t.timestamps
    end
    add_index :home_timeline_entries, :recipient_id
  end
end
