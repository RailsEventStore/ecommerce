require "test_helper"

class ProductsTest < InMemoryRESIntegrationTestCase
  include ActionView::Helpers::NumberHelper

  def setup
    super
  end

  def test_happy_path
    register_customer("Arkency")

    get "/products/new"
    assert_select "h1", "New Product"
    product_id = register_product("product name", 20.01, 10)
    follow_redirect!

    assert_equal "20.01",
                 number_to_currency(
                   Product.find(product_id).price,
                   unit: ""
                 )

    assert_select "h1", "Products"

    get "/products/#{product_id}/edit"
    patch "/products/#{product_id}",
          params: {
            "authenticity_token" => "[FILTERED]",
            product: { price: "20.02" }
          }
    stream = event_store.read.stream("ProductCatalog::Product$#{product_id}").to_a
    assert_equal 2, stream.size
    assert_equal "ProductCatalog::ProductPriceChanged", stream.last.event_type
    assert_equal 20.02, stream.last.data[:price]

    assert_equal "20.02",
                 number_to_currency(
                   Product.last.price,
                   unit: ""
                 )
  end

  def test_change_product_name
    register_customer("Arkency")

    get "/products/new"
    assert_select "h1", "New Product"
    product_id = register_product("product name", 20.01, 10)

    get "/products/#{product_id}/edit"
    patch "/products/#{product_id}",
          params: {
            "authenticity_token" => "[FILTERED]",
            product: { name: "Changed product name" }
          }
    product_stream = event_store.read.stream("ProductCatalog::Product$#{product_id}").to_a
    assert_equal 2, product_stream.size
    name_changed = product_stream.last
    assert_equal "ProductCatalog::ProductNameChanged", name_changed.event_type
    assert_equal "Changed product name", name_changed.data[:name]

    patch "/products/#{product_id}",
          params: {
            "authenticity_token" => "[FILTERED]",
            product: { name: "Changed product name" }
          }

    product_stream = event_store.read.stream("ProductCatalog::Product$#{product_id}").to_a
    assert_equal 2, product_stream.size
  end

  def test_does_not_crash_when_setting_products_price_to_0
    register_customer("Arkency")

    get "/products/new"
    assert_select "h1", "New Product"

    post "/products", params: { product: { name: 'name', price: 0, vat_rate: 10, sku: 'test' } }

    assert_response :unprocessable_entity
    assert_select "span", "Price must be greater than 0"
  end

  def test_does_not_crash_when_vat_rate_is_absent
    register_customer("Arkency")

    get "/products/new"
    assert_select "h1", "New Product"

    post "/products", params: { product: { name: 'name', price: 10, vat_rate: nil, sku: 'test' } }

    assert_response :unprocessable_entity
    assert_select "span", "Vat rate is not a number"
  end

  def test_does_not_crash_when_name_is_not_present
    register_customer("Arkency")

    get "/products/new"
    assert_select "h1", "New Product"

    post "/products", params: { product: { name: nil, price: 10, vat_rate: 23, sku: 'test' } }

    assert_response :unprocessable_entity
    assert_select "span", "Name can't be blank"
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end
