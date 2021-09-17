require "test_helper"

class CustomersTest < ActionDispatch::IntegrationTest
  def test_list_customers
    get "/customers"
    assert_response :success
  end
end
