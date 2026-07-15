require_relative "../test_helper"

class ProfileTest < InMemoryRESIntegrationTestCase
  def test_shows_the_users_posts_newest_first
    sign_up("alice", "pw")
    post_tweet("first from alice")
    post_tweet("second from alice")

    get("/users/alice")

    assert_response(:success)
    assert_select("[data-profile-handle]", text: "alice")
    assert_equal(
      ["second from alice", "first from alice"],
      css_select("[data-profile-post]").map(&:text)
    )
  end

  def test_shows_only_that_users_posts
    sign_up("alice", "pw")
    post_tweet("alice post")
    log_out
    create_account("bob", "pw")
    login("bob", "pw")
    post_tweet("bob post")

    get("/users/alice")

    assert_select("[data-profile-post]", text: "alice post")
    assert_select("[data-profile-post]", text: "bob post", count: 0)
  end

  def test_unknown_handle_returns_not_found
    get("/users/nobody")

    assert_response(:not_found)
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

  def post_tweet(body)
    post(tweets_path, params: { body: body })
    follow_redirect!
  end
end
