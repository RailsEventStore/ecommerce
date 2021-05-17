require "test_helper"

class BlogFlowTest < ActionDispatch::IntegrationTest

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
           "customer_id"=> 1,
           "commit"=>"Submit order"
         }
  end
end