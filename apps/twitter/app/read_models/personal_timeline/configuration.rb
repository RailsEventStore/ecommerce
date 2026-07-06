module PersonalTimeline
  class Post < ApplicationRecord
    self.table_name = "home_timeline_entries"
  end
  private_constant :Post

  def self.for(recipient_id)
    Post.where(recipient_id: recipient_id).order(created_at: :desc)
  end

  class AddPost
    def call(event)
      Post.create!(
        recipient_id: event.data.fetch(:recipient_id),
        author: event.data.fetch(:author),
        body: event.data.fetch(:body)
      )
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(AddPost.new, to: [::Social::PostDeliveredToTimeline])
    end
  end
end
