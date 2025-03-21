require "test_helper"

class RefundsTest < InMemoryRESIntegrationTestCase
  def setup
    skip "Refunds not yet integrated"
    super
    add_available_vat_rate(10)
  end

  def test_happy_path
    shopify_id = register_customer("Shopify")
    order_id = SecureRandom.uuid
    async_remote_id = register_product("Async Remote", 39, 10)
    fearless_id = register_product("Fearless Refactoring", 49, 10)

    add_product_to_basket(order_id, async_remote_id)
    add_product_to_basket(order_id, fearless_id)
    add_product_to_basket(order_id, fearless_id)
    submit_order(shopify_id, order_id)
    pay_order(order_id)

    get "/orders/#{order_id}"

    assert_select("button", "Refund")

    post "/orders/#{order_id}/refunds"
    follow_redirect!

    assert_order_line_row(async_remote_id, "Async Remote", 1)
    assert_order_line_row(fearless_id, "Fearless Refactoring", 2)
  end

  def test_renders_error_when_exceeds_available_quantity_to_refund
    shopify_id = register_customer("Shopify")
    order_id = SecureRandom.uuid
    async_remote_id = register_product("Async Remote", 39, 10)

    add_product_to_basket(order_id, async_remote_id)
    submit_order(shopify_id, order_id)
    pay_order(order_id)

    post "/orders/#{order_id}/refunds"
    follow_redirect!

    refund = Refunds::Refund.last

    add_item_to_refund(order_id, refund.uid, async_remote_id)
    add_item_to_refund(order_id, refund.uid, async_remote_id)
    follow_redirect!

    assert_select("#alert", "You cannot add more of this product to the refund than is in the original order.")
  end

  def test_renders_error_when_trying_to_remove_not_added_product
    shopify_id = register_customer("Shopify")
    order_id = SecureRandom.uuid
    async_remote_id = register_product("Async Remote", 39, 10)

    add_product_to_basket(order_id, async_remote_id)
    submit_order(shopify_id, order_id)
    pay_order(order_id)

    post "/orders/#{order_id}/refunds"
    follow_redirect!

    refund = Refunds::Refund.last

    remove_item_from_refund(order_id, refund.uid, async_remote_id)
    follow_redirect!

    assert_select("#alert",  "This product is not added to the refund.")
  end

  private

  def assert_order_line_row(product_id, product_name, quantity)
    assert_select("#order_line_product_#{product_id}") do
      assert_select("td", product_name)
      assert_select("td", "0 / #{quantity}")
    end
  end
end
