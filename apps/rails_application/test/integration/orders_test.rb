require "test_helper"

class OrdersTest < InMemoryRESIntegrationTestCase
  def setup
    super
    Rails.configuration.payment_gateway.call.reset
    register_store("Store 1")
    add_available_vat_rate(10)
  end

  def test_happy_path
    shopify_id = register_customer("Shopify")

    async_remote_id = register_product("Async Remote", 39, 10)
    fearless_id = register_product("Fearless Refactoring", 49, 10)

    another_order_id = create_order

    post "/orders",
         params: {
           "authenticity_token" => "[FILTERED]",
           "order_id" => another_order_id,
           "customer_id" => shopify_id,
           "commit" => "Submit order"
         }

    get "/"
    order_id = create_order

    assert_remove_buttons_not_visible(async_remote_id, fearless_id)

    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    post "/orders/#{order_id}/add_item?product_id=#{fearless_id}"
    post "/orders/#{order_id}/add_item?product_id=#{fearless_id}"
    get "/orders/#{order_id}/edit"
    assert_remove_buttons_visible(async_remote_id, fearless_id, order_id)

    apply_discount_10_percent(order_id)

    post "/orders",
         params: {
           "authenticity_token" => "[FILTERED]",
           "order_id" => order_id,
           "customer_id" => shopify_id,
           "commit" => "Submit order"
         }
    follow_redirect!
    assert_select("td", "$123.30")
    assert_select("dd", "Submitted")
    assert_select("dd", "Shopify")
    assert_select("td", "10.0%")
    get "/orders"
    post "/orders/#{order_id}/pay"
    follow_redirect!
    assert_select("td", text: "Paid")
    assert_payment_gateway_value(123.30)

    verify_shipping(order_id)
    verify_invoice_generation(order_id)

    assert_res_browser_order_history
  end

  def test_expiring_orders
    async_remote_id = register_product("Async Remote", 39, 10)

    get "/orders/new"
    follow_redirect!
    order_id = retrieve_order_id_from_url

    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    get "/orders"
    assert_select("td", "Draft")
    post "/orders/expire"
    follow_redirect!
    assert_select("td", "Expired")
  end

  def test_cancel
    shopify_id = register_customer("Shopify")

    async_remote_id = register_product("Async Remote", 39, 10)

    get "/"
    order_id = create_order
    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    post "/orders",
         params: {
           "authenticity_token" => "[FILTERED]",
           "order_id" => order_id,
           "customer_id" => shopify_id,
           "commit" => "Submit order"
         }

    post "/orders/#{order_id}/cancel"
    get "/orders/#{order_id}"
    assert_select("dd", "Cancelled")
  end

  def test_confirmed_order_doesnt_show_cancel_button
    shopify_id = register_customer("Shopify")

    async_remote_id = register_product("Async Remote", 39, 10)

    get "/"
    get "/orders/new"
    follow_redirect!
    order_id = retrieve_order_id_from_url

    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"

    get "/orders/#{order_id}"

    assert_select("button", text: "Cancel Order", count: 0)

    post "/orders",
         params: {
           "authenticity_token" => "[FILTERED]",
           "order_id" => order_id,
           "customer_id" => shopify_id,
           "commit" => "Submit order"
         }

    get "/orders/#{order_id}"
    assert_select("button", text: "History")
    assert_select("button", text: "Cancel Order", count: 1)

    post "/orders/#{order_id}/pay"
    follow_redirect!
    assert_select("td", text: "Paid")
    get "/orders/#{order_id}"
    assert_select("button", text: "History")
    assert_select("button", text: "Cancel Order", count: 0)
  end

  def test_order_value_doesnt_change_after_changing_price
    shopify_id = register_customer("Shopify")

    async_remote_id = register_product("Async Remote", 39, 10)

    get "/"
    order_id = create_order
    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"

    post "/orders",
         params: {
           "authenticity_token" => "[FILTERED]",
           "order_id" => order_id,
           "customer_id" => shopify_id,
           "commit" => "Submit order"
         }
    follow_redirect!
    get "/orders/#{order_id}"
    assert_select("td", text: "$39.00")
    assert_select("td", text: "$78.00")
    update_price(async_remote_id, 49)
    get "/orders/#{order_id}"

    assert_select("td", text: "$39.00")
    assert_select("td", text: "$78.00")
  end

  def test_discount_is_applied_for_new_order
    async_remote_id = register_product("Async Remote", 39, 10)
    fearless_id = register_product("Fearless Refactoring", 49, 10)
    shopify_id = register_customer("Shopify")

    order_id = create_order
    assert_nothing_raised { apply_discount_10_percent(order_id) }

    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    post "/orders/#{order_id}/add_item?product_id=#{fearless_id}"

    post "/orders",
         params: {
           "authenticity_token" => "[FILTERED]",
           "order_id" => order_id,
           "customer_id" => shopify_id,
           "commit" => "Submit order"
         }

    follow_redirect!
    assert_select("td", "$79.20")
    assert_select("dd", "Submitted")
    assert_select("td", "10.0%")
  end

  def test_empty_order_cannot_be_submitted
    shopify_id = register_customer("Shopify")

    get "/orders/new"
    follow_redirect!
    order_id = retrieve_order_id_from_url

    assert_no_changes -> { Orders.all_orders.count } do
      post "/orders",
            params: {
              "authenticity_token" => "[FILTERED]",
              "order_id" => order_id,
              "customer_id" => shopify_id,
              "commit" => "Submit order"
            }
    end
    follow_redirect!

    assert_select "#alert", "You can't submit an empty order"
  end

  def test_order_cannot_be_submitted_with_out_of_stock_product
    product_id = register_product("Fearless Refactoring", 4, 10)
    shopify_id = register_customer("Shopify")

    supply_product(product_id, 1)
    order_1_id = create_order
    order_2_id = create_order
    post "/orders/#{order_1_id}/add_item?product_id=#{product_id}"
    post "/orders/#{order_2_id}/add_item?product_id=#{product_id}"

    post "/orders", params: { order_id: order_1_id, customer_id: shopify_id }
    post "/orders", params: { order_id: order_2_id, customer_id: shopify_id }

    assert_equal "Order can not be submitted! Fearless Refactoring not available in requested quantity!", flash[:alert]
  end

  def test_shows_out_of_stock_badge
    shopify_id = register_customer("Shopify")
    async_remote_id = register_product("Async Remote", 39, 10)

    supply_product(async_remote_id, 1)

    order_id = create_order

    assert_select "td span", "1"

    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    post "/orders",
            params: {
              "authenticity_token" => "[FILTERED]",
              "order_id" => order_id,
              "customer_id" => shopify_id,
              "commit" => "Submit order"
            }

    get "/orders/new"
    follow_redirect!

    assert_select "td span", "0"
  end

  def test_current_time_promotion_is_applied
    register_store("Test Store")
    async_remote_id = register_product("Async Remote", 39, 10)
    shopify_id = register_customer("Shopify")

    create_active_time_promotion(50)
    get "/orders/new"
    follow_redirect!
    order_id = retrieve_order_id_from_url

    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"

    post "/orders",
         params: {
           "authenticity_token" => "[FILTERED]",
           "order_id" => order_id,
           "customer_id" => shopify_id,
           "commit" => "Submit order"
         }
    follow_redirect!

    assert_select("td", "$19.50")
    assert_select("dd", "Submitted")
    assert_select("td", "50.0%")
  end

  def test_unable_to_pay_for_not_submitted_order
    shopify_id = register_customer("Shopify")

    async_remote_id = register_product("Async Remote", 39, 10)
    fearless_id = register_product("Fearless Refactoring", 49, 10)

    another_order_id = create_order

    post "/orders",
         params: {
           "authenticity_token" => "[FILTERED]",
           "order_id" => another_order_id,
           "customer_id" => shopify_id,
           "commit" => "Submit order"
         }

    get "/"
    order_id = create_order

    assert_remove_buttons_not_visible(async_remote_id, fearless_id)

    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    post "/orders/#{order_id}/add_item?product_id=#{fearless_id}"
    post "/orders/#{order_id}/add_item?product_id=#{fearless_id}"
    get "/orders/#{order_id}/edit"
    assert_remove_buttons_visible(async_remote_id, fearless_id, order_id)

    apply_discount_10_percent(order_id)

    post "/orders/#{order_id}/pay"

    follow_redirect!
    assert_select "#alert", "Order is not in a valid state for payment"
    assert_select("td", text: "Not submitted")
  end

  def test_cannot_edit_order_from_different_store
    store_id_a = SecureRandom.uuid
    store_id_b = SecureRandom.uuid

    post "/admin/stores", params: { store_id: store_id_a, name: "Store A" }
    post "/admin/stores", params: { store_id: store_id_b, name: "Store B" }

    post "/switch_store", params: { store_id: store_id_b }
    get "/orders/new"
    follow_redirect!
    order_id_in_store_b = retrieve_order_id_from_url

    post "/switch_store", params: { store_id: store_id_a }
    get "/orders/#{order_id_in_store_b}/edit"

    assert_response(:not_found)
  end

  def test_cannot_show_order_from_different_store
    store_id_a = SecureRandom.uuid
    store_id_b = SecureRandom.uuid

    post "/admin/stores", params: { store_id: store_id_a, name: "Store A" }
    post "/admin/stores", params: { store_id: store_id_b, name: "Store B" }

    post "/switch_store", params: { store_id: store_id_b }
    get "/orders/new"
    follow_redirect!
    order_id_in_store_b = retrieve_order_id_from_url

    post "/switch_store", params: { store_id: store_id_a }
    get "/orders/#{order_id_in_store_b}"

    assert_response(:not_found)
  end

  private

  def retrieve_order_id_from_url
    request.path.split('/')[2]
  end

  def assert_remove_buttons_visible(async_remote_id, fearless_id, order_id)
    assert_match(
      /#{Regexp.escape(remove_item_order_path(id: order_id, product_id: async_remote_id))}/,
      response.body
    )
    assert_match(
      /#{Regexp.escape(remove_item_order_path(id: order_id, product_id: fearless_id))}/,
      response.body
    )
  end

  def assert_remove_buttons_not_visible(async_remote_id, fearless_id)
    url = request.original_url
    uri = URI.parse(url)
    path_components = uri.path.split("/")
    order_uuid = path_components[-2]

    assert_no_match(
      /#{Regexp.escape(remove_item_order_path(id: order_uuid, product_id: async_remote_id))}/,
      response.body
    )
    assert_no_match(
      /#{Regexp.escape(remove_item_order_path(id: order_uuid, product_id: fearless_id))}/,
      response.body
    )
  end

  def verify_shipping(order_id)
    get "/orders/#{order_id}"
    assert_select("dd", "Shipping address is missing.")
    assert_select("a", "Add shipment address")
    get "/orders/#{order_id}/shipping_address/edit"
    assert_select("label", "Addressee's full name (Person or Company)")
    put "/orders/#{order_id}/shipping_address",
        params: {
          "shipments_shipment" => {
            address_line_1: "123 Main Street",
            address_line_2: "Apt 1",
            address_line_3: "San Francisco",
            address_line_4: "US"
          }
        }
    follow_redirect!
    assert_select("dd", "Your shipment has been queued for processing.")
    get "/shipments"
    assert_select("td", "123 Main Street Apt 1 San Francisco US")
  end

  def verify_invoice_generation(order_id)
    get "/orders/#{order_id}"
    assert_select("a", "Add billing address")
    get "/orders/#{order_id}/billing_address/edit"
    assert_select("label", "Addressee's full name (Person or Company)")
    put "/orders/#{order_id}/billing_address",
        params: {
          "invoices_invoice" => {
            address_line_1: "44 Main Street",
            address_line_2: "Apt 2",
            address_line_3: "Francisco",
            address_line_4: "UK"
          }
        }
    follow_redirect!
    assert_select("button", "Issue now")
    post "/orders/#{order_id}/invoice"
    follow_redirect!

    assert_select("td", "Async Remote")
    assert_select("td", "$35.10")
    assert_select("td", "1")
    assert_select("td", "Fearless Refactoring")
    assert_select("td", "$44.10")
    assert_select("td", "2")
    assert_select("td", "$88.20")
    assert_select("td", "$123.30")
  end

  def assert_res_browser_order_history
    get "/res/api/streams/Orders%24all/relationships/events"
    event_names =
      JSON
        .load(body)
        .fetch("data")
        .map { |data| data.fetch("attributes").fetch("event_type") }

    assert(event_names.include?("Fulfillment::OrderConfirmed"))
    assert(event_names.include?("Pricing::PriceItemAdded"))
    assert(event_names.include?("Processes::TotalOrderValueUpdated"))
    assert(event_names.include?("Fulfillment::OrderRegistered"))
  end

  def assert_payment_gateway_value(value)
    assert_equal(
      1,
      Rails.configuration.payment_gateway.call.authorized_transactions.size
    )
    assert_equal(
      value,
      Rails.configuration.payment_gateway.call.authorized_transactions[0][1]
    )
  end

  def apply_discount_10_percent(order_id)
    get "/orders/#{order_id}/edit_discount"

    post "/orders/#{order_id}/update_discount?amount=10"
  end

  def create_active_time_promotion(discount)
    post "/time_promotions", params: {
      label: "Last Minute",
      discount: discount,
      start_time: Time.current - 1,
      end_time: Time.current + 1.minute
    }
  end
end