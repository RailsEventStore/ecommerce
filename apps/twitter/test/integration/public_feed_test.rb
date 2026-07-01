require_relative "../test_helper"

class PublicFeedTest < InMemoryRESIntegrationTestCase
  def test_anonymous_visitor_sees_the_global_feed
    command_bus.call(
      Social::PostTweet.new(
        tweet_id: SecureRandom.uuid,
        author: "alice",
        body: "Hello, fediverse"
      )
    )

    get(root_path)

    assert_response(:success)
    assert_select("[data-tweet-author]", text: "alice")
    assert_select("[data-tweet-body]", text: "Hello, fediverse")
  end

  def test_shows_newest_tweets_first
    command_bus.call(
      Social::PostTweet.new(tweet_id: SecureRandom.uuid, author: "alice", body: "first")
    )
    command_bus.call(
      Social::PostTweet.new(tweet_id: SecureRandom.uuid, author: "bob", body: "second")
    )

    get(root_path)

    bodies = css_select("[data-tweet-body]").map(&:text)
    assert_equal(["second", "first"], bodies)
  end
end
