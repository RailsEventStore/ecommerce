class CreateFeedTweets < ActiveRecord::Migration[8.1]
  def change
    create_table :feed_tweets do |t|
      t.uuid :uid, null: false
      t.string :author, null: false
      t.text :body, null: false
      t.timestamps
    end
    add_index :feed_tweets, :uid, unique: true
  end
end
