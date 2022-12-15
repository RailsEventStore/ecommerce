require "test_helper"

class ProductsTest < InMemoryRESIntegrationTestCase
  include ActionView::Helpers::NumberHelper
  cover "Products*"

  def setup
    super
  end

  def test_happy_path
    register_customer("Arkency")
    product_id = SecureRandom.uuid

    get "/products/new"
    assert_select "h1", "New Product"
    post "/products",
         params: {
           "authenticity_token" => "[FILTERED]",
           "product_id" => product_id,
           "name" => "product name",
           price: "20.01",
           "vat_rate" => "10"
         }
    follow_redirect!


    Sidekiq::Job.drain_all
    assert_equal "20.01", number_to_currency(Products::Product.find(product_id).price, unit: "")

    assert_select "h1", "Products"

    get "/products/#{product_id}/edit"
    patch "/products/#{product_id}",
         params: {
           "authenticity_token" => "[FILTERED]",
           "product_id" => product_id,
           price: "20.02",
         }

    Sidekiq::Job.drain_all
    assert_equal "20.02", number_to_currency(Products::Product.find(product_id).price, unit: "")
  end
end
