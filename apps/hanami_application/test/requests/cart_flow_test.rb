# frozen_string_literal: true

require "test_helper"

class CartFlowTest < Hanami::Minitest::RequestTest
  test "buying a product" do
    get "/"

    assert(last_response.ok?)
    assert_includes(last_response.body, "Domain-Driven Rails")
    assert_includes(last_response.body, "Your cart is empty.")

    post "/cart/items", product_id: first_product_id, _csrf_token: csrf_token
    follow_redirect!

    assert_includes(last_response.body, "added to cart")
    assert_includes(last_response.body, "Submit order")

    post "/cart/submit", _csrf_token: csrf_token
    follow_redirect!

    assert_match(%r{Order \d{4}/\d{2}/\d+}, last_response.body)
    assert_includes(last_response.body, "Your order has been delivered.")
  end

  test "submitting an empty cart" do
    get "/"
    post "/cart/submit", _csrf_token: csrf_token
    follow_redirect!

    assert_includes(last_response.body, "Your cart is empty")
  end

  private

  def first_product_id
    last_response.body[/option value="([0-9a-f-]{36})"/, 1]
  end

  def csrf_token
    last_response.body[/name="_csrf_token" value="([^"]+)"/, 1]
  end
end
