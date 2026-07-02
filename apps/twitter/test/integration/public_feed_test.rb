require_relative "../test_helper"

class PublicFeedTest < InMemoryRESIntegrationTestCase
  def test_anonymous_visitor_sees_the_global_feed
    sign_up("alice", "s3cret")
    post_tweet("Hello, fediverse")
    log_out

    get(root_path)

    assert_response(:success)
    assert_select("[data-tweet-author]", text: "alice")
    assert_select("[data-tweet-body]", text: "Hello, fediverse")
  end

  def test_shows_newest_tweets_first
    sign_up("alice", "s3cret")
    post_tweet("first")
    post_tweet("second")
    log_out

    get(root_path)

    bodies = css_select("[data-tweet-body]").map(&:text)
    assert_equal(["second", "first"], bodies)
  end

  private

  def sign_up(handle, password)
    post(registrations_path, params: { handle: handle, password: password })
    follow_redirect!
  end

  def post_tweet(body)
    post(tweets_path, params: { body: body })
    follow_redirect!
  end

  def log_out
    delete(session_path)
    follow_redirect!
  end
end
