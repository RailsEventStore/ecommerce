require "test_helper"

class BlogFlowTest < ActionDispatch::IntegrationTest
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
    async_remote = ProductCatalog::Product.create(name: "Async Remote", price: 39)
    fearless = ProductCatalog::Product.create(name: "Fearless Refactoring", price: 49)
    get "/"
    get "/orders/new"
    post "/orders/#{order_id}/add_item?product_id=#{async_remote.id}"
    follow_redirect!
    assert_select("td", "$39.00")
    post "/orders/#{order_id}/add_item?product_id=#{fearless.id}"
    follow_redirect!
    assert_select("td", "$88.00")
    post "/orders", params:
      {
        "authenticity_token"=>"[FILTERED]",
        "order_id" => order_id,
        "customer_id"=> shopify.id,
        "commit"=>"Submit order"
      }
    follow_redirect!
    assert_select("td", "$88.00")
    assert_select("p", "State: Submitted")
    assert_select("p", "Customer: Shopify")
  end
end