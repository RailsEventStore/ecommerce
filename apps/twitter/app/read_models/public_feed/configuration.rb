module PublicFeed
  class Tweet < ApplicationRecord
    self.table_name = "feed_tweets"
  end
  private_constant :Tweet

  def self.recent
    Tweet.order(created_at: :desc)
  end

  class AddTweet
    def call(event)
      Tweet.create!(
        uid: event.data.fetch(:tweet_id),
        author: event.data.fetch(:author),
        body: event.data.fetch(:body)
      )
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(AddTweet.new, to: [::Social::TweetPosted])
    end
  end
end
