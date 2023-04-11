require "test_helper"

class PublicOfferTest < InMemoryRESIntegrationTestCase
  cover "PublicOffer*"

  def setup
    super
  end

  def test_happy_path
    arkency_id = register_customer('Arkency')
    Sidekiq::Job.drain_all
    register_product("Async Remote", 39, 10)
    get "/clients"
    login(arkency_id)
    assert_select("a", "Products")
    get "/client/products"
    assert_select("td", "Async Remote")
    assert_select("td", "$39.00")
  end

  def test_showing_orders_with_information_about_the_lowest_price
    client_id = register_customer('Arkency')
    product1_id = register_product("Async Remote", 45, 10)
    product2_id = register_product("Rails meets React.js", 50, 10)
    update_price(product1_id, 30)
    update_price(product2_id, 25)
    update_price(product2_id, 70)

    Sidekiq::Job.drain_all

    get "/clients"
    login(client_id)
    get "/client/products"
    assert css_select("#lowest-price-info-#{product1_id}").empty?
    assert css_select("#lowest-price-info-#{product2_id}").present?

    info_icon = css_select("#lowest-price-info-#{product2_id}").first
    assert_equal info_icon.attributes.fetch("title").value, "Lowest recent price: $25.00"
  end

end
