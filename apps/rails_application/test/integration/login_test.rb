require "test_helper"

class LoginTest < InMemoryRESIntegrationTestCase

  def setup
    super
    register_store("Store 1")
  end

  def test_login
    password = "1234qwer"
    customer_id = register_customer("Arkency")
    set_password(customer_id, password)

    post "/login", params: { client_id: customer_id, password: password }
    follow_redirect!

    assert_select("h1", "Arkency")
  end

  def test_login_with_incorrect_password
    password = "1234qwer"
    customer_id = register_customer("Arkency")
    set_password(customer_id, password)

    post "/login",
         params: {
           client_id: customer_id,
           password: "Wrong password"
         }
    follow_redirect!

    assert_equal("/clients", path)
  end

  def test_forged_cookie_does_not_grant_access
    customer_id = register_customer("Victim")

    cookies["client_id"] = customer_id

    get "/client_orders"

    assert_redirected_to("/logout")
  end

  def test_not_existing_customer_session_should_log_out_and_redirect_to_login
    post "/login", params: { client_id: "not-existing-customer" }
    follow_redirect!
    follow_redirect!
    follow_redirect!

    assert_equal("/clients", path)
  end

  private

  def set_password(customer_id, password)
    account_id = SecureRandom.uuid
    password_hash = Digest::SHA256.hexdigest(password)

    run_command(Authentication::RegisterAccount.new(account_id: account_id))
    run_command(
      Authentication::ConnectAccountToClient.new(
        account_id: account_id,
        client_id: customer_id
      )
    )
    run_command(
      Authentication::SetPasswordHash.new(
        account_id: account_id,
        password_hash: password_hash
      )
    )

    customer_id
  end
end
