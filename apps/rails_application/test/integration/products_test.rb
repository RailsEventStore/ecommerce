require "test_helper"

class ProductsTest < InMemoryRESIntegrationTestCase
  include ActionView::Helpers::NumberHelper

  def setup
    super
  end

  def test_happy_path
    register_store("Store 1")
    add_available_vat_rate(10, "10S")
    register_customer("Arkency")
    product_id = SecureRandom.uuid

    get "/products/new"
    assert_select "h1", "New Product"
    post "/products",
         params: {
           "authenticity_token" => "[FILTERED]",
           "product_id" => product_id,
           "name" => "product name",
           :price => "20.01",
           "vat_rate_code" => "10S"
         }
    follow_redirect!

    assert_equal "20.01",
                 number_to_currency(
                   Products.find_product(product_id).price,
                   unit: ""
                 )

    assert_select "h1", "Products"

    get "/products/#{product_id}/edit"
    patch "/products/#{product_id}",
          params: {
            "authenticity_token" => "[FILTERED]",
            "product_id" => product_id,
            :price => "20.02"
          }

    assert_equal "20.02",
                 number_to_currency(
                   Products.find_product(product_id).price,
                   unit: ""
                 )
  end

  def test_does_not_crash_when_setting_products_price_to_0
    register_store("Store 1")
    register_customer("Arkency")
    product_id = SecureRandom.uuid

    get "/products/new"
    assert_select "h1", "New Product"
    post "/products",
         params: {
           "authenticity_token" => "[FILTERED]",
           "product_id" => product_id,
           "name" => "product name",
           "price" => "0",
           "vat_rate_code" => "10"
         }

    assert_response :unprocessable_entity
    assert_select "span", "Price must be greater than 0"
  end

  def test_does_not_crash_when_vat_rate_is_absent
    register_store("Store 1")
    register_customer("Arkency")
    product_id = SecureRandom.uuid

    get "/products/new"
    assert_select "h1", "New Product"
    post "/products",
         params: {
           "authenticity_token" => "[FILTERED]",
           "product_id" => product_id,
           "name" => "product name",
           "price" => "100"
         }

    assert_response :unprocessable_entity
    assert_select "span", "Vat rate code can't be blank"
  end

  def test_does_not_crash_when_name_is_not_present
    register_store("Store 1")
    register_customer("Arkency")
    product_id = SecureRandom.uuid

    get "/products/new"
    assert_select "h1", "New Product"
    post "/products",
         params: {
           "authenticity_token" => "[FILTERED]",
           "product_id" => product_id,
           "price" => "100",
           "vat_rate_code" =>"10"
         }

    assert_response :unprocessable_entity
    assert_select "span", "Name can't be blank"
  end

  def test_products_are_filtered_by_current_store
    store_1_id = register_store("Store 1")
    store_2_id = register_store("Store 2")
    add_available_vat_rate(10)

    post switch_store_path, params: { store_id: store_1_id }
    register_product("Product 1", 10, "10")

    post switch_store_path, params: { store_id: store_2_id }
    register_product("Product 2", 20, "10")

    get products_path
    assert_select "td", "Product 2"
    assert_select "td", { text: "Product 1", count: 0 }

    post switch_store_path, params: { store_id: store_1_id }
    get products_path
    assert_select "td", "Product 1"
    assert_select "td", { text: "Product 2", count: 0 }
  end
end
