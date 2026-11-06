require "test_helper"

class PersistedItemRemovalTest < RealRESIntegrationTestCase
  include ActionCable::TestHelper

  cover "OrdersController#remove_item"
  cover "Client::OrdersController#remove_item"
  cover "Orders::SubmitService#submit_order"

  BroadcastUnavailable = Class.new(StandardError)

  def setup
    @customer_id = SecureRandom.uuid
    @product_id = SecureRandom.uuid
    @previous_broadcaster = Rails.configuration.broadcaster

    post "/admin/stores", params: { store_id: SecureRandom.uuid, name: "Test Store" }
    post "/customers", params: { customer_id: @customer_id, name: "Customer" }
    post "/available_vat_rates", params: { code: "10", rate: 10 }
    post "/products", params: { product_id: @product_id, name: "Book", price: 37, vat_rate_code: "10" }
    post "/products/#{@product_id}/supplies", params: { quantity: 1 }
    post "/login", params: { client_id: @customer_id }
  end

  def teardown
    Rails.configuration.broadcaster = @previous_broadcaster
  end

  def test_submit_buttons_follow_basket_contents_through_hotwire_even_when_the_total_is_zero
    patch "/products/#{@product_id}", params: { product_id: @product_id, price: 0 }
    post "/products/#{@product_id}/supplies", params: { quantity: 3 }

    %w[orders client_orders].each do |scope|
      get "/#{scope}/new"
      follow_redirect!
      @order_id = request.path.split("/")[2]
      assert_select("[id$='_submit_button']", count: 1)
      assert_select("button[form='form'], #form input[type='submit']", count: 0)

      assert_submit_button_update(scope, "add_item", 1)
      assert_basket(1, "$0.00")
      assert_submit_button_update(scope, "add_item", 1)
      assert_basket(2, "$0.00")
      assert_submit_button_update(scope, "remove_item", 1)
      assert_basket(1, "$0.00")
      assert_submit_button_update(scope, "remove_item", 0)
      assert_basket(0, "$0.00")
      assert_submit_button_update(scope, "add_item", 1)
      assert_basket(1, "$0.00")
    end
  end

  def test_admin_can_retry_failed_removal_and_cannot_submit_the_emptied_order
    assert_removal_can_be_retried("/orders", :ok)

    post "/orders/#{@order_id}/submit", params: { customer_id: @customer_id }

    assert_redirected_to("/orders/#{@order_id}/edit")
    follow_redirect!
    assert_select("#alert", "You can't submit an empty order")
    assert_recorded_empty_order_rejection

    post "/orders/#{@order_id}/add_item", params: { product_id: @product_id }
    post "/orders/#{@order_id}/submit", params: { customer_id: @customer_id }

    assert_redirected_to("/orders/#{@order_id}")
    follow_redirect!
    assert_select("#notice", "Your order has been submitted")
  end

  def test_client_can_retry_failed_removal_and_cannot_submit_the_emptied_order
    assert_removal_can_be_retried("/client_orders", :no_content)

    post "/client_orders", params: { order_id: @order_id }

    assert_redirected_to("/client_orders/#{@order_id}/edit")
    follow_redirect!
    assert_select("#alert", "You can't submit an empty order")
    assert_recorded_empty_order_rejection

    post "/client_orders/#{@order_id}/add_item", params: { product_id: @product_id }
    post "/client_orders", params: { order_id: @order_id }

    assert_redirected_to("/client_orders/#{@order_id}")
    follow_redirect!
    assert_select("#notice", "Your order has been submitted")
  end

  def test_submission_rolls_back_when_assigning_the_customer_fails
    get "/orders/new"
    follow_redirect!
    @order_id = request.path.split("/")[2]
    post "/orders/#{@order_id}/add_item", params: { product_id: @product_id }

    post "/orders/#{@order_id}/submit", params: { customer_id: SecureRandom.uuid }
    follow_redirect!

    assert_select("#alert", "Order can not be submitted! Customer does not exist.")

    post "/orders/#{@order_id}/submit", params: { customer_id: @customer_id }
    follow_redirect!

    assert_select("#notice", "Your order has been submitted")
  end

  private

  def assert_submit_button_update(scope, action, count)
    capture_broadcasts("#{scope == "orders" ? "orders_order" : "client_orders"}_#{@order_id}") do
      post "/#{scope}/#{@order_id}/#{action}", params: { product_id: @product_id }
      assert_response(:success)
    end.map { |message| Nokogiri::HTML5.fragment(message).at_css("turbo-stream") }
      .select { |update| update["target"].end_with?("#{@order_id}_submit_button") }.sole.then do |update|
        assert_equal("update", update["action"])
        assert_equal(count, update.css("template [type='submit']").size)
      end
  end

  def assert_recorded_empty_order_rejection
    get "/res/streams/#{Rack::Utils.escape("Pricing::OrderAcceptance$#{@order_id}")}"

    assert_response(:success)
    assert_select("a", text: "Pricing::OrderAcceptanceRequested")
    assert_select("a", text: "Pricing::EmptyOrderAcceptanceRejected")
  end

  def assert_removal_can_be_retried(orders_path, response_status)
    get "#{orders_path}/new"
    follow_redirect!
    @order_id = request.path.split("/")[2]
    post "#{orders_path}/#{@order_id}/add_item", params: { product_id: @product_id }
    assert_response(response_status)
    assert_basket(1, "$37.00")

    remove_with_broadcast_failure(orders_path)

    assert_basket(1, "$37.00")

    post "#{orders_path}/#{@order_id}/remove_item", params: { product_id: @product_id }

    assert_response(response_status)
    assert_basket(0, "$0.00")
  end

  def remove_with_broadcast_failure(orders_path)
    Rails.configuration.broadcaster = ->(*) { raise BroadcastUnavailable }
    post "#{orders_path}/#{@order_id}/remove_item",
         params: { product_id: @product_id },
         env: { "action_dispatch.show_exceptions" => :all }
    assert_response(:internal_server_error)
  ensure
    Rails.configuration.broadcaster = @previous_broadcaster
  end

  def assert_basket(quantity, total)
    get "/orders/#{@order_id}/edit"
    assert_response(:success)
    assert_select("#orders_order_#{@product_id}_quantity", quantity.to_s)
    assert_select("#orders_order_#{@order_id}_discounted_value", total)
    assert_select("#orders_order_#{@order_id}_submit_button", count: 1)
    assert_select("button[type='submit'][form='form']", count: quantity.zero? ? 0 : 1)

    get "/client_orders/#{@order_id}/edit"
    assert_response(:success)
    assert_select("#client_orders_#{@product_id}_product_quantity", quantity.to_s)
    assert_select("#client_orders_#{@order_id}_discounted_value", total)
    assert_select("#client_orders_#{@order_id}_submit_button", count: 1)
    assert_select("#form input[type='submit']", count: quantity.zero? ? 0 : 1)
  end
end
