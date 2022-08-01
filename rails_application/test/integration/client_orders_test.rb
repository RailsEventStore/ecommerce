require "test_helper"

class ClientOrdersTests < InMemoryRESIntegrationTestCase
  include ActionView::Helpers::NumberHelper
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

    get "/clients"

    assert_select("button", "Login")
    assert_select("select", "Arkency")

    login(arkency_id)
    assert_select("h1", "Arkency")
    assert_select("p", "No orders to display.")

    order_id = SecureRandom.uuid
    add_item_to_basket_for_order(async_remote_id, order_id)
    submit_order_for_customer(arkency_id, order_id)
    get "/client_orders"
    order_price = number_to_currency(Orders::Order.find_by(uid: order_id).discounted_value)

    assert_select("td", "Submitted")
    assert_select("td", order_price)

    pay_order(order_id)
    get "/client_orders"
    assert_select("td", "Paid")

    cancel_submitted_order_for_customer(arkency_id)
    get "/client_orders"
    assert_select("td", "Cancelled")
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

  def pay_order(order_id)
    post "/orders/#{order_id}/pay"
  end

  def cancel_order(order_id)
    post "/orders/#{order_id}/cancel"
  end

  def cancel_submitted_order_for_customer(customer_id)
    order_id = SecureRandom.uuid
    anti_if = register_product('Anti If', 99, 10)

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
