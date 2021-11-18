require "test_helper"

class OrdersTest < InMemoryRESIntegrationTestCase
  cover "Orders*"

  def setup
    super
    Rails.configuration.payment_gateway.call.reset
    Orders::Order.destroy_all
  end

  def test_submitting_empty_order
    arkency_id = SecureRandom.uuid
    run_command(
      Crm::RegisterCustomer.new(customer_id: arkency_id, name: "Arkency")
    )

    get "/"
    assert_select "h1", "Orders"
    get "/orders/new"
    assert_select "h1", "New Order"
    post "/orders",
         params: {
           "authenticity_token" => "[FILTERED]",
           "order_id" => SecureRandom.uuid,
           "customer_id" => arkency_id,
           "commit" => "Submit order"
         }
  end

  def test_happy_path
    shopify_id = SecureRandom.uuid
    run_command(
      Crm::RegisterCustomer.new(customer_id: shopify_id, name: "Shopify")
    )

    order_id = SecureRandom.uuid
    another_order_id = SecureRandom.uuid

    async_remote_id = SecureRandom.uuid
    run_command(
      ProductCatalog::RegisterProduct.new(
        product_id: async_remote_id,
        name: "Async Remote"
      )
    )
    run_command(Pricing::SetPrice.new(product_id: async_remote_id, price: 39))

    fearless_id = SecureRandom.uuid
    run_command(
      ProductCatalog::RegisterProduct.new(
        product_id: fearless_id,
        name: "Fearless Refactoring"
      )
    )
    run_command(Pricing::SetPrice.new(product_id: fearless_id, price: 49))

    post "/orders",
         params: {
           "authenticity_token" => "[FILTERED]",
           "order_id" => another_order_id,
           "customer_id" => shopify_id,
           "commit" => "Submit order"
         }

    get "/"
    get "/orders/new"
    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    follow_redirect!
    assert_select("td", "$39.00")
    post "/orders/#{order_id}/add_item?product_id=#{fearless_id}"
    follow_redirect!
    assert_select("td", "$88.00")
    post "/orders/#{order_id}/add_item?product_id=#{fearless_id}"
    follow_redirect!
    assert_select("td", "$137.00")

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
    assert_select("a", "Invoice")
    get "/invoices/#{order_id}"
    assert_select("dd", "Shopify")
    assert_select("dd", "Arkency Ecommerce")
    assert_select("dd", "2021.11.15")
    assert_select("td", "0%")
    get "/orders"
    post "/orders/#{order_id}/pay"
    follow_redirect!
    assert_select("td", text: "Paid")
    assert_payment_gateway_value(123.30)
    assert_res_browser_order_history
  end

  def test_expiring_orders
    order_id = SecureRandom.uuid
    async_remote_id = SecureRandom.uuid
    run_command(
      ProductCatalog::RegisterProduct.new(
        product_id: async_remote_id,
        name: "Async Remote"
      )
    )
    run_command(Pricing::SetPrice.new(product_id: async_remote_id, price: 39))

    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    follow_redirect!
    assert_select("td", "$39.00")
    get "/orders"
    assert_select("td", "Draft")
    post "/orders/expire"
    follow_redirect!
    assert_select("td", "Expired")
  end

  def test_cancel
    shopify_id = SecureRandom.uuid
    run_command(
      Crm::RegisterCustomer.new(customer_id: shopify_id, name: "Shopify")
    )
    order_id = SecureRandom.uuid
    async_remote_id = SecureRandom.uuid
    run_command(
      ProductCatalog::RegisterProduct.new(
        product_id: async_remote_id,
        name: "Async Remote"
      )
    )
    run_command(Pricing::SetPrice.new(product_id: async_remote_id, price: 39))

    get "/"
    get "/orders/new"
    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    follow_redirect!
    assert_select("td", "$39.00")
    post "/orders",
         params: {
           "authenticity_token" => "[FILTERED]",
           "order_id" => order_id,
           "customer_id" => shopify_id,
           "commit" => "Submit order"
         }

    run_command(Ordering::CancelOrder.new(order_id: order_id))
    get "/orders/#{Orders::Order.last.id}"
    assert_select("dd", "Cancelled")
  end

  def test_reset_discount
    shopify_id = SecureRandom.uuid
    run_command(
      Crm::RegisterCustomer.new(customer_id: shopify_id, name: "Shopify")
    )

    order_id = SecureRandom.uuid

    async_remote_id = SecureRandom.uuid
    run_command(
      ProductCatalog::RegisterProduct.new(
        product_id: async_remote_id,
        name: "Async Remote"
      )
    )
    run_command(Pricing::SetPrice.new(product_id: async_remote_id, price: 137))

    get "/"
    get "/orders/new"
    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    follow_redirect!
    assert_select("td", "$137.00")
    assert_select("a", count: 0, text: "Reset")

    apply_discount_10_percent(order_id)

    assert_select("a", "Reset")
    post "/orders/#{order_id}/reset_discount"
    follow_redirect!
    assert_select("td", "$137.00")
    assert_select("a", count: 0, text: "Reset")
  end

  private

  def assert_res_browser_order_history
    get "/res/api/streams/Orders$all/relationships/events"
    event_names =
      JSON
        .load(body)
        .fetch("data")
        .map { |data| data.fetch("attributes").fetch("event_type") }
    assert(event_names.include?("Ordering::OrderPaid"))
    assert(event_names.include?("Ordering::ItemAddedToBasket"))
    assert(event_names.include?("Pricing::OrderTotalValueCalculated"))
    assert(event_names.include?("Ordering::OrderSubmitted"))
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
    assert_select("a", "Edit discount")
    get "/orders/#{order_id}/edit_discount"
    assert_select("label", "Percentage")

    post "/orders/#{order_id}/update_discount?amount=10"
    follow_redirect!
    assert_select("td", "$123.30")
  end
end
