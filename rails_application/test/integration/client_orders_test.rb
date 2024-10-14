require_relative "../test_helper"

class ClientOrdersTests < InMemoryRESIntegrationTestCase
  include ActionView::Helpers::NumberHelper

  def setup
    super
    Rails.configuration.payment_gateway.call.reset
    add_available_vat_rate(10)
  end

  def test_happy_path
    arkency_id = register_customer("Arkency")
    async_remote_id = register_product("Async Remote", 39, 10)
    fearless_id = register_product("Fearless Refactoring", 49, 10)

    get "/clients"
    assert_select("button", { count: 0, text: "Log out" })
    assert_select("button", "Login")
    assert_select("select", "Arkency")

    login(arkency_id)
    assert_select("h1", "Arkency")
    assert_select("p", "No orders to display.")

    order_id = SecureRandom.uuid
    add_item_to_basket_for_order(async_remote_id, order_id)
    get "/client_orders/#{order_id}/edit"
    assert_match(
      /#{Regexp.escape(remove_item_client_order_path(id: order_id, product_id: async_remote_id))}/,
      response.body
    )
    assert_no_match(
      /#{Regexp.escape(remove_item_client_order_path(id: order_id, product_id: fearless_id))}/,
      response.body
    )

    submit_order_for_customer(arkency_id, order_id)
    get "/client_orders"
    order_price =
      number_to_currency(Orders::Order.find_by(uid: order_id).discounted_value)

    assert_select("td", "Submitted")
    assert_select("td", order_price)

    pay_order(order_id)
    get "/client_orders"
    assert_select("td", "Paid")

    cancel_submitted_order_for_customer(arkency_id)
    get "/client_orders"
    assert_select("td", "Cancelled")

    assert_select("button", "Log out")
    get "/logout"
    follow_redirect!
    assert_select("button", "Login")
    assert_select("select", "Arkency")
  end

  def test_creating_order_as_client
    arkency_id = register_customer("Arkency")
    async_remote_id = register_product("Async Remote", 39, 10)

    get "/clients"
    login(arkency_id)
    order_id = SecureRandom.uuid
    get "/client_orders/new"
    as_client_add_item_to_basket_for_order(async_remote_id, order_id)
    as_client_submit_order_for_customer(order_id)
    get "/client_orders"
    order_price =
      number_to_currency(Orders::Order.find_by(uid: order_id).discounted_value)
    assert_select("td", "Submitted")
    assert_select("td", order_price)
  end

  def test_paid_orders_summary
    customer_id = register_customer("Customer Shop")
    product_1_id = register_product("Fearless Refactoring", 4, 10)
    product_2_id = register_product("Asycn Remote", 3, 10)

    login(customer_id)
    visit_client_orders
    assert_select "Total paid orders", false

    order_and_pay(customer_id, SecureRandom.uuid, product_1_id, product_2_id)
    visit_client_orders

    assert_orders_summary("$7.00")

    order_and_pay(customer_id, SecureRandom.uuid, product_1_id)
    visit_client_orders

    assert_orders_summary("$11.00")
  end

  def test_adding_the_same_product_twice_bug
    customer_id = register_customer("Customer Shop")
    product_id = register_product("Fearless Refactoring", 4, 10)

    login(customer_id)
    visit_client_orders

    order_id = SecureRandom.uuid
    as_client_add_item_to_basket_for_order(product_id, order_id)
    as_client_add_item_to_basket_for_order(product_id, order_id)
    assert_equal(204, response.status)
  end

  def test_adding_product_which_is_not_available_anymore
    customer_1_id = register_customer("Arkency")
    customer_2_id = register_customer("Customer Shop")
    product_id = register_product("Fearless Refactoring", 4, 10)

    supply_product(product_id, 1)
    session_1 = login_as(customer_1_id)
    session_2 = login_as(customer_2_id)

    session_1.get "/client_orders"
    session_2.get "/client_orders"

    order_1_id = SecureRandom.uuid
    session_1.post "/client_orders/#{order_1_id}/add_item?product_id=#{product_id}"
    order_and_pay(customer_1_id, order_1_id, product_id)

    order_2_id = SecureRandom.uuid
    session_2.post "/client_orders/#{order_2_id}/add_item?product_id=#{product_id}"

    assert session_2.redirect?
    assert session_2.response.location.include?(
             "/client_orders/#{order_2_id}/edit"
           )
    assert_equal "Product not available in requested quantity!",
                 session_2.flash[:alert]
  end

  def test_adding_product_which_is_not_available_in_requested_quantity
    customer_id = register_customer("Customer Shop")
    product_id = register_product("Fearless Refactoring", 4, 10)

    supply_product(product_id, 1)
    login(customer_id)
    visit_client_orders

    order_id = SecureRandom.uuid
    as_client_add_item_to_basket_for_order(product_id, order_id)
    as_client_add_item_to_basket_for_order(product_id, order_id)

    assert_redirected_to "/client_orders/#{order_id}/edit"
    assert_equal "Product not available in requested quantity!", flash[:alert]
  end

  def test_empty_order_cannot_be_submitted
    customer_id = register_customer("Customer Shop")

    login(customer_id)
    visit_client_orders

    order_id = SecureRandom.uuid
    assert_no_changes -> { ClientOrders::Order.count } do
      as_client_submit_order_for_customer(order_id)
    end

    assert_select "#alert", "You can't submit an empty order"
  end

  def test_shows_out_of_stock_badge
    shopify_id = register_customer("Shopify")
    order_id = SecureRandom.uuid
    async_remote_id = register_product("Async Remote", 39, 10)

    supply_product(async_remote_id, 1)
    login(shopify_id)
    get "/client_orders/new"

    assert_select "td span", text: "out of stock", count: 0

    as_client_add_item_to_basket_for_order(async_remote_id, order_id)
    as_client_submit_order_for_customer(order_id)

    get "/client_orders/new"
    follow_redirect!

    assert_select "td span", "out of stock"
  end

  def test_current_time_promotion_is_applied
    customer_id = register_customer("Customer Shop")
    product_id = register_product("Fearless Refactoring", 4, 10)
    create_current_time_promotion

    login(customer_id)
    visit_client_orders

    order_id = SecureRandom.uuid
    as_client_add_item_to_basket_for_order(product_id, order_id)
    as_client_submit_order_for_customer(order_id)

    assert_select "tr td", "$2.00"
  end

  def test_using_coupon_applies_discount
    customer_id = register_customer("Customer Shop")
    product_id = register_product("Fearless Refactoring", 4, 10)
    register_coupon("Coupon", "coupon10", 10)

    login(customer_id)
    visit_client_orders

    order_id = SecureRandom.uuid
    as_client_add_item_to_basket_for_order(product_id, order_id)
    as_client_use_coupon(order_id, "COUPON10")

    assert_select "#notice", "Coupon applied!"

    as_client_submit_order_for_customer(order_id)

    assert_select "tr td", "$3.60"
  end

  def test_using_coupon_with_wrong_code
    customer_id = register_customer("Customer Shop")
    product_id = register_product("Fearless Refactoring", 4, 10)
    register_coupon("Coupon", "coupon10", 10)

    login(customer_id)
    visit_client_orders

    order_id = SecureRandom.uuid
    as_client_add_item_to_basket_for_order(product_id, order_id)
    as_client_use_coupon(order_id, "WRONGCODE")

    assert_select "#alert", "Coupon not found!"
  end

  def test_using_coupon_twice
    customer_id = register_customer("Customer Shop")
    product_id = register_product("Fearless Refactoring", 4, 10)
    register_coupon("Coupon", "coupon10", 10)

    login(customer_id)
    visit_client_orders

    order_id = SecureRandom.uuid
    as_client_add_item_to_basket_for_order(product_id, order_id)
    as_client_use_coupon(order_id, "COUPON10")
    as_client_use_coupon(order_id, "COUPON10")

    assert_select "#alert", "Coupon already used!"
  end

  private

  def submit_order_for_customer(customer_id, order_id)
    post "/orders", params: { order_id: order_id, customer_id: customer_id }
    follow_redirect!
  end

  def add_item_to_basket_for_order(async_remote_id, order_id)
    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
  end

  def as_client_submit_order_for_customer(order_id)
    post "/client_orders", params: { order_id: order_id }
    follow_redirect!
  end

  def as_client_add_item_to_basket_for_order(async_remote_id, order_id)
    post "/client_orders/#{order_id}/add_item?product_id=#{async_remote_id}"
  end

  def as_client_use_coupon(order_id, code)
    post "/client_orders/#{order_id}/use_coupon", params: { coupon_code: code }
    follow_redirect!
  end

  def cancel_order(order_id)
    post "/orders/#{order_id}/cancel"
  end

  def cancel_submitted_order_for_customer(customer_id)
    order_id = SecureRandom.uuid
    anti_if = register_product("Anti If", 99, 10)

    add_item_to_basket_for_order(anti_if, order_id)
    add_item_to_basket_for_order(anti_if, order_id)
    submit_order_for_customer(customer_id, order_id)
    cancel_order(order_id)
  end

  def order_and_pay(customer_id, order_id, *product_ids)
    product_ids.each do |product_id|
      as_client_add_item_to_basket_for_order(product_id, order_id)
    end
    submit_order_for_customer(customer_id, order_id)
    pay_order(order_id)
  end

  def assert_orders_summary(summary)
    assert_select "tr" do
      assert_select "td:nth-child(1)", "Total paid orders"
      assert_select "td:nth-child(2)", summary
    end
  end

  def update_price(product_id, new_price)
    patch "/products/#{product_id}",
          params: {
            "authenticity_token" => "[FILTERED]",
            "product_id" => product_id,
            :price => new_price
          }
  end

  def login_as(client_id)
    open_session { |sess| sess.post "/login", params: { client_id: client_id } }
  end

  def create_current_time_promotion(discount: 50, start_time: Time.current - 1.day, end_time: Time.current + 1.day)
    post "/time_promotions", params: {
      label: "Last Minute",
      discount: discount,
      start_time: start_time,
      end_time: end_time
    }
  end
end
