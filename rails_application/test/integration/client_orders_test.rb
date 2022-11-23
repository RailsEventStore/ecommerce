require "test_helper"

class ClientOrdersTests < InMemoryRESIntegrationTestCase
  include ActionView::Helpers::NumberHelper
  include ActiveJob::TestHelper
  cover "ClientOrders*"

  def setup
    super
    Rails.configuration.payment_gateway.call.reset
    ClientOrders::Client.destroy_all
    ClientOrders::Order.destroy_all
    Orders::Order.destroy_all
  end

  def test_happy_path
    arkency_id = register_customer('Arkency')
    async_remote_id = register_product("Async Remote", 39, 10)
    perform_enqueued_jobs

    get "/clients"
    assert_select("button", { count: 0, text: "Log out" })
    assert_select("button", "Login")
    assert_select("select", "Arkency")

    login(arkency_id)
    assert_select("h1", "Arkency")
    assert_select("p", "No orders to display.")

    order_id = SecureRandom.uuid
    add_item_to_basket_for_order(async_remote_id, order_id)
    perform_enqueued_jobs
    submit_order_for_customer(arkency_id, order_id)
    perform_enqueued_jobs
    get "/client_orders"
    order_price = number_to_currency(Orders::Order.find_by(uid: order_id).discounted_value)

    assert_select("td", "Submitted")
    assert_select("td", order_price)

    pay_order(order_id)
    perform_enqueued_jobs
    get "/client_orders"
    assert_select("td", "Paid")

    cancel_submitted_order_for_customer(arkency_id)
    perform_enqueued_jobs
    get "/client_orders"
    assert_select("td", "Cancelled")

    assert_select("button", "Log out")
    get "/logout"
    follow_redirect!
    assert_select("button", "Login")
    assert_select("select", "Arkency")
  end

  def test_creating_order_as_client
    arkency_id = register_customer('Arkency')
    async_remote_id = register_product("Async Remote", 39, 10)
    perform_enqueued_jobs

    get "/clients"
    login(arkency_id)
    order_id = SecureRandom.uuid
    get "/client_orders/new"
    as_client_add_item_to_basket_for_order(async_remote_id, order_id)
    perform_enqueued_jobs
    as_client_submit_order_for_customer(order_id)
    perform_enqueued_jobs
    get "/client_orders"
    order_price = number_to_currency(Orders::Order.find_by(uid: order_id).discounted_value)
    assert_select("td", "Submitted")
    assert_select("td", order_price)
  end

  private

  def submit_order_for_customer(customer_id, order_id)
    post "/orders", params: { order_id: order_id, customer_id: customer_id }
    follow_redirect!
  end

  def add_item_to_basket_for_order(async_remote_id, order_id)
    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    follow_redirect!
  end

  def as_client_submit_order_for_customer(order_id)
    post "/client_orders", params: { order_id: order_id }
    follow_redirect!
  end

  def as_client_add_item_to_basket_for_order(async_remote_id, order_id)
    post "/client_orders/#{order_id}/add_item?product_id=#{async_remote_id}"
  end

  def pay_order(order_id)
    post "/orders/#{order_id}/pay"
  end

  def cancel_order(order_id)
    post "/orders/#{order_id}/cancel"
  end

  def cancel_submitted_order_for_customer(customer_id)
    order_id = SecureRandom.uuid
    anti_if = register_product('Anti If', 99, 10)
    perform_enqueued_jobs

    add_item_to_basket_for_order(anti_if, order_id)
    add_item_to_basket_for_order(anti_if, order_id)
    submit_order_for_customer(customer_id, order_id)
    cancel_order(order_id)
  end

  def login(arkency_id)
    post "/login", params: { client_id: arkency_id }
    follow_redirect!
  end
end
