require_relative "../test_helper"

class PersonalTimelineTest < InMemoryRESIntegrationTestCase
  def test_shows_tweets_from_followed_users
    create_account("bob", "pw")
    sign_up("alice", "pw")
    follow("bob")
    log_out

    login("bob", "pw")
    post_tweet("Hello from bob")
    log_out

    login("alice", "pw")
    get(home_path)

    assert_select("[data-timeline-author]", text: "bob")
    assert_select("[data-timeline-body]", text: "Hello from bob")
  end

  def test_shows_your_own_posts_in_your_timeline
    sign_up("alice", "pw")

    post_tweet("Hello from me")
    get(home_path)

    assert_select("[data-timeline-author]", text: "alice")
    assert_select("[data-timeline-body]", text: "Hello from me")
  end

  def test_hides_tweets_from_users_you_do_not_follow
    create_account("bob", "pw")
    sign_up("alice", "pw")
    log_out

    login("bob", "pw")
    post_tweet("Hidden from alice")
    log_out

    login("alice", "pw")
    get(home_path)

    assert_select("[data-timeline-body]", count: 0)
  end

  private

  def create_account(handle, password)
    sign_up(handle, password)
    log_out
  end

  def sign_up(handle, password)
    post(registrations_path, params: { handle: handle, password: password })
    follow_redirect!
  end

  def login(handle, password)
    post(session_path, params: { handle: handle, password: password })
    follow_redirect!
  end

  def log_out
    delete(session_path)
    follow_redirect!
  end

  def follow(handle)
    post(follows_path, params: { handle: handle })
    follow_redirect!
  end

  def post_tweet(body)
    post(tweets_path, params: { body: body })
    follow_redirect!
  end
end
