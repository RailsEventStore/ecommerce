require_relative "test_helper"

module Social
  class SocialTest < Test
    cover "Social*"

    def test_post_tweet
      tweet_id = SecureRandom.uuid
      command_bus.call(PostTweet.new(tweet_id: tweet_id, author: "alice", body: "Hello, fediverse"))

      assert_event_published(
        TweetPosted.new(data: { tweet_id: tweet_id, author: "alice", body: "Hello, fediverse" })
      )
    end
  end
end
