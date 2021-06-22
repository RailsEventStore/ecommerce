require "test_helper"

class OrdersTest < ActionDispatch::IntegrationTest
  cover 'Orders*'

  def test_submitting_empty_order
    arkency = Customer.create(name: "Arkency")

    get "/"
    assert_select "h1", "Orders"
    get "/orders/new"
    assert_select "h1", "New Order"
    post "/orders", params:
         {
           "authenticity_token"=>"[FILTERED]",
           "order_id"=>"288c590d-b7dc-429f-8d82-79ebf2d5aabc",
           "customer_id"=> arkency.id,
           "commit"=>"Submit order"
         }
  end

  def test_happy_path
    shopify = Customer.create(name: "Shopify")
    order_id = "288c590d-b7dc-429f-8d82-79ebf2d5aabc"
    another_order_id = "1111590d-b7dc-429f-8d82-79ebf2d5aabc"

    product_uid = SecureRandom.uuid
    product_id = run_command(ProductCatalog::RegisterProduct.new(product_uid: product_uid, name: "Async Remote"))
    run_command(Pricing::SetPrice.new(product_id: product_id, price: 39))
    async_remote = ProductCatalog::Product.find_by(id: product_id)

    product_uid = SecureRandom.uuid
    product_id = run_command(ProductCatalog::RegisterProduct.new(product_uid: product_uid, name: "Fearless Refactoring"))
    run_command(Pricing::SetPrice.new(product_id: product_id, price: 49))
    fearless = ProductCatalog::Product.find_by(id: product_id)

    post "/orders", params:
      {
        "authenticity_token"=>"[FILTERED]",
        "order_id" => another_order_id,
        "customer_id"=> shopify.id,
        "commit"=>"Submit order"
      }

    get "/"
    get "/orders/new"
    post "/orders/#{order_id}/add_item?product_id=#{async_remote.id}"
    follow_redirect!
    assert_select("td", "$39.00")
    post "/orders/#{order_id}/add_item?product_id=#{fearless.id}"
    follow_redirect!
    assert_select("td", "$88.00")
    post "/orders/#{order_id}/add_item?product_id=#{fearless.id}"
    follow_redirect!
    assert_select("td", "$137.00")
    post "/orders", params:
      {
        "authenticity_token"=>"[FILTERED]",
        "order_id" => order_id,
        "customer_id"=> shopify.id,
        "commit"=>"Submit order"
      }
    follow_redirect!
    assert_select("td", "$137.00")
    assert_select("p", "State: Submitted")
    assert_select("p", "Customer: Shopify")
    get "/orders"
    post "/orders/#{order_id}/pay"
    follow_redirect!
    assert_select("td", "Ready to ship (paid)")
  end

  def test_expiring_orders
    order_id = "388c590d-b7dc-429f-8d82-79ebf2d5aabc"
    product_uid = SecureRandom.uuid
    product_id = run_command(ProductCatalog::RegisterProduct.new(product_uid: product_uid, name: "Async Remote"))
    run_command(Pricing::SetPrice.new(product_id: product_id, price: 39))
    async_remote = ProductCatalog::Product.find_by(id: product_id)

    post "/orders/#{order_id}/add_item?product_id=#{async_remote.id}"
    follow_redirect!
    assert_select("td", "$39.00")
    get "/orders"
    assert_select("td", "Draft")
    post "/orders/expire"
    follow_redirect!
    assert_select("td", "Expired")
  end

  def test_cancel
    shopify = Customer.create(name: "Shopify")
    order_id = "288c590d-b7dc-429f-8d82-79ebf2d5aabc"
    product_uid = SecureRandom.uuid
    product_id = run_command(ProductCatalog::RegisterProduct.new(product_uid: product_uid, name: "Async Remote"))
    run_command(Pricing::SetPrice.new(product_id: product_id, price: 39))
    async_remote = ProductCatalog::Product.find_by(id: product_id)

    get "/"
    get "/orders/new"
    post "/orders/#{order_id}/add_item?product_id=#{async_remote.id}"
    follow_redirect!
    assert_select("td", "$39.00")
    post "/orders", params:
      {
        "authenticity_token"=>"[FILTERED]",
        "order_id" => order_id,
        "customer_id"=> shopify.id,
        "commit"=>"Submit order"
      }
    follow_redirect!
    get "/admin/orders"
    assert_select("td", order_id)
    get "/admin/orders/#{Orders::Order.last.id}"
    post "/admin/orders/#{Orders::Order.last.id}/cancel"
    follow_redirect!
    assert_select("td", "Cancelled")
  end
end