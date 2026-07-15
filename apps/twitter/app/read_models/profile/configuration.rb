module Profile
  class Post < ApplicationRecord
    self.table_name = "profile_posts"
  end
  private_constant :Post

  def self.posts_of(author_id)
    Post.where(author_id: author_id).order(created_at: :desc)
  end

  class AddPost
    def call(event)
      Post.create!(
        author_id: event.data.fetch(:author_id),
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
