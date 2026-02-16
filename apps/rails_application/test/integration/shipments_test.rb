
require "test_helper"

class ShipmentsTest < InMemoryRESIntegrationTestCase

  def test_list_shipments
    store_id = register_store("Test Store")
    add_available_vat_rate(10)

    shopify_id = register_customer("Shopify")
    async_remote_id = register_product("Async Remote", 39, 10)

    create_shipment_in_store(shopify_id, async_remote_id, store_id, "123 Main Street")

    get "/shipments"

    assert_response :success
    assert_select("td", "123 Main Street Apt 1 San Francisco US")
  end

  def test_shipment_page
    store_id = register_store("Test Store")
    add_available_vat_rate(10)

    shopify_id = register_customer("Shopify")
    async_remote_id = register_product("Async Remote", 39, 10)

    create_shipment_in_store(shopify_id, async_remote_id, store_id, "123 Main Street")

    get "/shipments"
    assert_response :success
    assert_select("a[href^='/shipments/']", "Show Shipment")

    shipment_path = css_select("a[href^='/shipments/']").first["href"]
    get shipment_path

    assert_response :success
    assert_select("dd", "123 Main Street Apt 1 San Francisco US")
    assert_select("td", "Async Remote")
    assert_select("td", "1")
  end

  def test_shipments_index_only_shows_shipments_from_current_store
    store_a_id = register_store("Store A")
    store_b_id = register_store("Store B")

    add_available_vat_rate(10)

    shopify_id = register_customer("Shopify")
    async_remote_id = register_product("Async Remote", 39, 10)

    create_shipment_in_store(shopify_id, async_remote_id, store_b_id, "456 Store B Ave")
    create_shipment_in_store(shopify_id, async_remote_id, store_a_id, "123 Store A St")

    get "/shipments"

    assert_response :success
    assert_select("td", "123 Store A St Apt 1 San Francisco US")
    refute_select("td", "456 Store B Ave Apt 1 San Francisco US")
  end

  private

  def create_shipment_in_store(customer_id, product_id, store_id, address_line_1)
    post "/switch_store", params: { store_id: store_id }

    get "/orders/new"
    follow_redirect!
    order_id = request.path.split('/')[2]

    post "/orders/#{order_id}/add_item?product_id=#{product_id}"
    put "/orders/#{order_id}/shipping_address",
        params: {
          "shipments_shipment" => {
            address_line_1: address_line_1,
            address_line_2: "Apt 1",
            address_line_3: "San Francisco",
            address_line_4: "US"
          }
        }
    post "/orders/#{order_id}/submit",
         params: {
           "customer_id" => customer_id
         }

    order_id
  end
end
