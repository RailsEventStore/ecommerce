require "test_helper"

class ProductsTest < InMemoryRESIntegrationTestCase
  cover "Products*"

  def test_add_product_with_worng_vat_rate_code
    product_id = SecureRandom.uuid
    post "/products",
         params: {
           "authenticity_token" => "[FILTERED]",
           "product_id" => SecureRandom.uuid,
           "name" => "Product 1",
           "vat_rate" => "50",
         }
    follow_redirect!
    assert_select("#notice", "Selected VAT rate not applicable")
  end
end
