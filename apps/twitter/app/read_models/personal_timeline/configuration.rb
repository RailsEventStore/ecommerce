module PersonalTimeline
  class Follow < ApplicationRecord
    self.table_name = "home_timeline_follows"
  end
  private_constant :Follow

  class Entry < ApplicationRecord
    self.table_name = "home_timeline_entries"
  end
  private_constant :Entry

  def self.for(recipient_id)
    Entry.where(recipient_id: recipient_id).order(created_at: :desc)
  end

  class RecordFollow
    def call(event)
      Follow.create!(
        follower_id: event.data.fetch(:follower_id),
        followee_id: event.data.fetch(:followee_id)
      )
    end
  end

  class RemoveFollow
    def call(event)
      Follow.where(
        follower_id: event.data.fetch(:follower_id),
        followee_id: event.data.fetch(:followee_id)
      ).delete_all
    end
  end

  class FanOut
    def call(event)
      Follow.where(followee_id: event.data.fetch(:author_id)).pluck(:follower_id).each do |follower_id|
        Entry.create!(
          recipient_id: follower_id,
          author: event.data.fetch(:author),
          body: event.data.fetch(:body)
        )
      end
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(RecordFollow.new, to: [::Social::UserFollowed])
      event_store.subscribe(RemoveFollow.new, to: [::Social::UserUnfollowed])
      event_store.subscribe(FanOut.new, to: [::Social::TweetPosted])
    end
  end
end
