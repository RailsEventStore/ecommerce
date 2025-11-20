
require "test_helper"

class ShipmentsTest < InMemoryRESIntegrationTestCase
  def setup
    super
    add_available_vat_rate(10)
  end

  def test_list_shipments
    shopify_id = register_customer("Shopify")
    order_id = SecureRandom.uuid
    async_remote_id = register_product("Async Remote", 39, 10)

    add_product_to_basket(order_id, async_remote_id)
    put "/orders/#{order_id}/shipping_address",
        params: {
          "shipments_shipment" => {
            address_line_1: "123 Main Street",
            address_line_2: "Apt 1",
            address_line_3: "San Francisco",
            address_line_4: "US"
          }
        }
    submit_order(shopify_id, order_id)

    order = Orders.find_order(order_id)

    get "/shipments"

    assert_response :success
    assert_select("td", order.number)
    assert_select("td", "123 Main Street Apt 1 San Francisco US")
  end

  def test_shipment_page
    shopify_id = register_customer("Shopify")
    order_id = SecureRandom.uuid
    async_remote_id = register_product("Async Remote", 39, 10)

    add_product_to_basket(order_id, async_remote_id)
    put "/orders/#{order_id}/shipping_address",
        params: {
          "shipments_shipment" => {
            address_line_1: "123 Main Street",
            address_line_2: "Apt 1",
            address_line_3: "San Francisco",
            address_line_4: "US"
          }
        }
    submit_order(shopify_id, order_id)

    shipment = Shipments::Shipment.find_by(order_uid: order_id)
    order = Orders.find_order(order_id)

    get "/shipments/#{shipment.id}"
    assert_response :success
    assert_select("dd", order.number)
    assert_select("dd", "123 Main Street Apt 1 San Francisco US")
    assert_select("td", "Async Remote")
    assert_select("td", "1")
  end
end
