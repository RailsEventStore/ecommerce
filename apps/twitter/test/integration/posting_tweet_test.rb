require_relative "../test_helper"

class PostingTweetTest < InMemoryRESIntegrationTestCase
  def test_signed_in_user_posts_a_tweet
    sign_up("alice", "s3cret")

    post(tweets_path, params: { body: "Hello from the UI" })
    follow_redirect!

    assert_select("[data-tweet-author]", text: "alice")
    assert_select("[data-tweet-body]", text: "Hello from the UI")
  end

  def test_anonymous_visitor_cannot_post
    post(tweets_path, params: { body: "sneaky" })
    follow_redirect!

    get(root_path)
    assert_select("[data-tweet-body]", count: 0)
  end

  def test_compose_form_hidden_when_not_signed_in
    get(root_path)

    assert_select("form[action='#{tweets_path}']", count: 0)
  end

  private

  def sign_up(handle, password)
    post(registrations_path, params: { handle: handle, password: password })
    follow_redirect!
  end
end
