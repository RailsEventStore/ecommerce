require "test_helper"

class CustomersTest < InMemoryRESIntegrationTestCase
  def test_list_customers
    get "/customers"
    assert_response :success
  end

  def test_vips
    customer_id = register_customer("Customer Shop")
    perform_enqueued_jobs(only: Customers::RegisterCustomer)

    patch "/customers/#{customer_id}"
    perform_enqueued_jobs(only: Customers::PromoteToVip)
    follow_redirect!
    assert_select("td", "Already a VIP")
  end
end
