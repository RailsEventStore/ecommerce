require "test_helper"

class LoginTest < InMemoryRESIntegrationTestCase
  cover "Authentication*"

  def setup
    super
    Customers::Customer.destroy_all
  end

  def test_login
    password = "1234qwer"
    customer_id = register_customer("Arkency")
    set_password(customer_id, password)

    post "/login", params: { client_id: customer_id, password: password }
    follow_redirect!

    assert_select("h1", "Arkency")
    assert_equal customer_id, cookies["client_id"]
  end


  def test_login_with_incorrect_password
    password = "1234qwer"
    customer_id = register_customer("Arkency")
    set_password(customer_id, password)

    post "/login", params: { client_id: customer_id, password: "Wrong password" }
    follow_redirect!

    refute cookies["client_id"].present?
  end

  def test_cookies_set_to_not_existing_customer_should_log_out_and_redirect_to_login
    cookies["client_id"] = "not-existing-customer"

    get "/client_orders"
    follow_redirect!
    follow_redirect!

    refute cookies["client_id"].present?
    assert_equal "/clients", response.original_url
  end

  private

  def set_password(customer_id, password)
    account_id = SecureRandom.uuid
    password_hash = Digest::SHA256.hexdigest(password)

    run_command(Authentication::RegisterAccount.new(account_id: account_id))
    run_command(Authentication::ConnectAccountToClient.new(account_id: account_id, client_id: customer_id))
    run_command(Authentication::SetPasswordHash.new(account_id: account_id, password_hash: password_hash))
    Sidekiq::Job.drain_all

    cookies["client_id"] = nil
    customer_id
  end
end
