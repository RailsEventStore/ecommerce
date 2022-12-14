require "test_helper"

class CustomersTest < InMemoryRESIntegrationTestCase
  def test_list_customers
    get "/customers"
    assert_response :success
  end

  def test_vips
    customer_id = register_customer("Customer Shop")
    Customers::RegisterCustomer.drain

    patch "/customers/#{customer_id}"
    Customers::PromoteToVip.drain
    follow_redirect!
    assert_select("td", "Already a VIP")
  end
end
