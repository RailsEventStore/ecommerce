require "test_helper"

class CatalogTest < InMemoryRESIntegrationTestCase
  def test_catalogs_start_empty
    get root_path
    assert_response(:success)
    assert_match(/Catalog/, response.body)
    assert_select("li", count: 0)

    get admin_root_path
    assert_response(:success)
    assert_match(/Admin Catalog/, response.body)
    assert_select("li", count: 0)
  end

  def test_admin_creates_product_visible_in_both_catalogs
    get admin_root_path
    assert_response(:success)
    assert_select("input[name=?]", "admin_catalog_product[name]")
    assert_select("input[name=?]", "admin_catalog_product[price]")

    post admin_catalog_path, params: {
      admin_catalog_product: {
        name: "Event Sourcing in Ruby",
        price: "12.34"
      }
    }
    assert_redirected_to(admin_root_path)

    follow_redirect!
    assert_response(:success)
    assert_select("li", text: "Event Sourcing in Ruby, $12.34")

    get root_path
    assert_response(:success)
    assert_select("li", text: "Event Sourcing in Ruby, $12.34")
  end
end
