require_relative "../test_helper"

class FollowingTest < InMemoryRESIntegrationTestCase
  def test_user_follows_another_and_sees_them_in_following_list
    create_account("bob", "pw")
    sign_up("alice", "pw")

    post(follows_path, params: { handle: "bob" })
    follow_redirect!

    assert_select("[data-following]", text: "bob")
  end

  def test_user_can_unfollow
    create_account("bob", "pw")
    sign_up("alice", "pw")
    post(follows_path, params: { handle: "bob" })
    follow_redirect!

    delete(follow_path("bob"))
    follow_redirect!

    assert_select("[data-following]", count: 0)
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

  def log_out
    delete(session_path)
    follow_redirect!
  end
end
