class CreateProfilePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :profile_posts do |t|
      t.uuid :author_id, null: false
      t.string :author, null: false
      t.text :body, null: false
      t.timestamps
    end
    add_index :profile_posts, :author_id
  end
end
