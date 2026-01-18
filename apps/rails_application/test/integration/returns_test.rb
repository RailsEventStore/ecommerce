require "test_helper"

class ReturnsTest < InMemoryRESIntegrationTestCase
  def setup
    super
    register_store("Store 1")
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

    assert_select("button", "Return")

    post "/orders/#{order_id}/returns"
    follow_redirect!

    assert_order_line_row(async_remote_id, "Async Remote", 1)
    assert_order_line_row(fearless_id, "Fearless Refactoring", 2)
  end

  def test_renders_error_when_exceeds_available_quantity_to_return
    shopify_id = register_customer("Shopify")
    order_id = SecureRandom.uuid
    async_remote_id = register_product("Async Remote", 39, 10)

    add_product_to_basket(order_id, async_remote_id)
    submit_order(shopify_id, order_id)
    pay_order(order_id)

    post "/orders/#{order_id}/returns"
    follow_redirect!

    return_record = Returns::Return.last

    add_item_to_return(order_id, return_record.uid, async_remote_id)
    add_item_to_return(order_id, return_record.uid, async_remote_id)
    follow_redirect!

    assert_select("#alert", "You cannot add more of this product to the return than is in the original order.")
  end

  def test_renders_error_when_trying_to_remove_not_added_product
    shopify_id = register_customer("Shopify")
    order_id = SecureRandom.uuid
    async_remote_id = register_product("Async Remote", 39, 10)

    add_product_to_basket(order_id, async_remote_id)
    submit_order(shopify_id, order_id)
    pay_order(order_id)

    post "/orders/#{order_id}/returns"
    follow_redirect!

    return_record = Returns::Return.last

    remove_item_from_return(order_id, return_record.uid, async_remote_id)
    follow_redirect!

    assert_select("#alert",  "This product is not added to the return.")
  end

  private

  def assert_order_line_row(product_id, product_name, quantity)
    assert_select("#order_line_product_#{product_id}") do
      assert_select("td", product_name)
      assert_select("td", "0 / #{quantity}")
    end
  end
end
