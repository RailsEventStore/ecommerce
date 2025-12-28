require "test_helper"

class SuppliesTest < InMemoryRESIntegrationTestCase
  def setup
    super
    add_available_vat_rate(10)
  end

  def test_happy_path
    product_id = register_product("Async Remote", 100, 10)

    get "/products/#{product_id}/supplies/new"
    assert_select "h1", "Supply"
    post "/products/#{product_id}/supplies",
          params: {
            "authenticity_token" => "[FILTERED]",
            "product_id" => product_id,
            "quantity" => "1"
          }
    follow_redirect!

    assert_select "#notice", "Stock level changed"
  end

  def test_renders_validation_error_when_quantity_is_not_present
    product_id = register_product("Async Remote", 100, 10)

    get "/products/#{product_id}/supplies/new"
    assert_select "h1", "Supply"
    post "/products/#{product_id}/supplies",
          params: {
            "authenticity_token" => "[FILTERED]",
            "product_id" => product_id,
            "quantity" => ""
          }

    assert_response :unprocessable_entity
    assert_select "span", "Quantity can't be blank"
  end

  def test_renders_validation_error_when_quantity_is_not_a_number
    product_id = register_product("Async Remote", 100, 10)

    get "/products/#{product_id}/supplies/new"
    assert_select "h1", "Supply"
    post "/products/#{product_id}/supplies",
          params: {
            "authenticity_token" => "[FILTERED]",
            "product_id" => product_id,
            "quantity" => "not a number"
          }

    assert_response :unprocessable_entity
    assert_select "span", "Quantity is not a number"
  end

  def test_renders_validation_error_when_quantity_is_zero
    product_id = register_product("Async Remote", 100, 10)

    get "/products/#{product_id}/supplies/new"
    assert_select "h1", "Supply"
    post "/products/#{product_id}/supplies",
          params: {
            "authenticity_token" => "[FILTERED]",
            "product_id" => product_id,
            "quantity" => "0"
          }

    assert_response :unprocessable_entity
    assert_select "span", "Quantity must be greater than 0"
  end
end
