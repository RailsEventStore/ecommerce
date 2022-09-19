require "test_helper"

class PublicOfferTest < InMemoryRESIntegrationTestCase
  cover "PublicOffer*"

  def setup
    super
  end

  def test_happy_path
    arkency_id = register_customer('Arkency')
    register_product("Async Remote", 39, 10)
    get "/clients"
    login(arkency_id)
    assert_select("a", "Products")
    get "/client/products"
    assert_select("td", "Async Remote")
    assert_select("td", "$39.00")
  end

end
