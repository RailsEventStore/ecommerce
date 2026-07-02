class CreateFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :follows do |t|
      t.uuid :follower_id, null: false
      t.uuid :followee_id, null: false
      t.timestamps
    end
    add_index :follows, [:follower_id, :followee_id], unique: true
    add_index :follows, :follower_id
  end
end
