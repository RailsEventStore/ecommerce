module PublicFeed
  class Post < ApplicationRecord
    self.table_name = "feed_tweets"
  end
  private_constant :Post

  def self.recent
    Post.order(created_at: :desc)
  end

  class AddPost
    def call(event)
      Post.create!(
        uid: event.data.fetch(:post_id),
        author: event.data.fetch(:author),
        body: event.data.fetch(:body)
      )
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(AddPost.new, to: [::Social::PostPublished])
    end
  end
end
