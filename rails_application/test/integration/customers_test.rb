require "test_helper"

class CustomersTest < InMemoryRESIntegrationTestCase
  def test_list_customers
    get "/customers"
    assert_response :success
  end

  def test_vips
    customer_id = register_customer("Customer Shop")
    patch "/customers/#{customer_id}"
    follow_redirect!
    assert_select("td", "Already a VIP")
  end

end
