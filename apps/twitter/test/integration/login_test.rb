require_relative "../test_helper"

class LoginTest < InMemoryRESIntegrationTestCase
  def test_user_logs_out_and_logs_back_in
    register("alice", "s3cret")

    delete(session_path)
    follow_redirect!
    assert_select("[data-current-user]", count: 0)

    post(session_path, params: { handle: "alice", password: "s3cret" })
    follow_redirect!
    assert_select("[data-current-user]", text: "alice")
  end

  def test_login_with_wrong_password_does_not_sign_in
    register("alice", "s3cret")
    delete(session_path)
    follow_redirect!

    post(session_path, params: { handle: "alice", password: "wrong" })

    assert_select("[data-current-user]", count: 0)
  end

  private

  def register(handle, password)
    post(registrations_path, params: { handle: handle, password: password })
    follow_redirect!
  end
end
