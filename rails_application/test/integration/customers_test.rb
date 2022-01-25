require "test_helper"

class CustomersTest < InMemoryRESIntegrationTestCase
  def test_list_customers
    get "/customers"
    assert_response :success
  end

  def test_cancel
    customer_id = SecureRandom.uuid
    run_command(
        Crm::RegisterCustomer.new(customer_id: customer_id, name: "Customer Shop")
    )
    patch "/customers/#{customer_id}"
    follow_redirect!
    assert_select("td", "Already a VIP")
  end

end
