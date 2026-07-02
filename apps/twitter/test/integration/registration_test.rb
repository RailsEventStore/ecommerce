require_relative "../test_helper"

class RegistrationTest < InMemoryRESIntegrationTestCase
  def test_visitor_registers_and_is_signed_in
    post(registrations_path, params: { handle: "alice", password: "s3cret" })
    follow_redirect!

    assert_response(:success)
    assert_select("[data-current-user]", text: "alice")
  end

  def test_anonymous_visitor_is_not_signed_in
    get(root_path)

    assert_response(:success)
    assert_select("[data-current-user]", count: 0)
  end
end
