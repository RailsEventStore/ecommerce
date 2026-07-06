require_relative "../test_helper"

module PublicFeed
  class PublicFeedTest < InMemoryRESTestCase
    cover "PublicFeed*"

    def test_adds_tweet_to_feed_on_tweet_posted
      tweet_id = SecureRandom.uuid
      publish_tweet(tweet_id: tweet_id, author: "alice", body: "Hello")

      assert_equal(1, PublicFeed.recent.count)
      assert_equal(tweet_id, PublicFeed.recent.first.uid)
      assert_equal("alice", PublicFeed.recent.first.author)
      assert_equal("Hello", PublicFeed.recent.first.body)
    end

    def test_returns_tweets_newest_first
      older = SecureRandom.uuid
      newer = SecureRandom.uuid
      publish_tweet(tweet_id: older, author: "alice", body: "first")
      publish_tweet(tweet_id: newer, author: "bob", body: "second")

      assert_equal([newer, older], PublicFeed.recent.map(&:uid))
    end

    def test_recent_is_empty_without_tweets
      assert_equal([], PublicFeed.recent.to_a)
    end

    private

    def publish_tweet(tweet_id:, author:, body:)
      event_store.publish(
        ::Social::TweetPosted.new(
          data: { tweet_id: tweet_id, author_id: SecureRandom.uuid, author: author, body: body }
        )
      )
    end
  end
end
