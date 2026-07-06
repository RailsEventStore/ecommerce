class DropHomeTimelineFollows < ActiveRecord::Migration[8.1]
  def change
    drop_table :home_timeline_follows do |t|
      t.uuid :follower_id, null: false
      t.uuid :followee_id, null: false
      t.timestamps

      t.index :followee_id
    end
  end
end
