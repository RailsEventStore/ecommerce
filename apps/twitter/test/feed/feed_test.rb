require_relative "../test_helper"

module Feed
  class FeedTest < InMemoryRESTestCase
    cover "Feed*"

    def test_adds_tweet_to_feed_on_tweet_posted
      tweet_id = SecureRandom.uuid
      publish_tweet(tweet_id: tweet_id, author: "alice", body: "Hello")

      assert_equal(1, Feed.recent.count)
      assert_equal(tweet_id, Feed.recent.first.uid)
      assert_equal("alice", Feed.recent.first.author)
      assert_equal("Hello", Feed.recent.first.body)
    end

    def test_returns_tweets_newest_first
      older = SecureRandom.uuid
      newer = SecureRandom.uuid
      publish_tweet(tweet_id: older, author: "alice", body: "first")
      publish_tweet(tweet_id: newer, author: "bob", body: "second")

      assert_equal([newer, older], Feed.recent.map(&:uid))
    end

    def test_recent_is_empty_without_tweets
      assert_equal([], Feed.recent.to_a)
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
