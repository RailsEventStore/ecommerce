require "test_helper"

class MissingResourcesTest < InMemoryRESIntegrationTestCase


  def test_order_not_found
    get "/orders/123"
    assert_response :not_found
  end

  def test_invoice_not_found
    get "/invoices/123"
    assert_response :not_found
  end
end
