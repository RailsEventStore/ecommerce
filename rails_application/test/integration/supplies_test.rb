require "test_helper"

class SuppliesTest < InMemoryRESIntegrationTestCase
  def setup
    super
  end

  def test_supply_new_product
    create_product
    product = Product.find_by(sku:)
    increase_stock_level_by_10(product.id)

    follow_redirect!

    assert_select "tr#product_#{product.id}" do
      assert_select "td", "10"
    end
    assert_equal(10, product.reload.stock_level)
  end

  def test_supply_product_with_existing_stock
    create_product
    product = Product.find_by(sku:)
    increase_stock_level_by_10(product.id)

    assert_changes -> { Product.find(product.id).stock_level }, from: 10, to: 20 do
      increase_stock_level_by_10(product.id)
    end

    follow_redirect!

    assert_select "tr#product_#{product.id}" do
      assert_select "td", "20"
    end
  end

  private

  def increase_stock_level_by_10(product_id)
    post "/products/#{product_id}/supplies", params: { product_id: product_id, quantity: 10 }
  end

  def create_product
    post "/products", params: { product: { name: "Stanley Cup", price: 100, vat_rate: 23, sku: } }
  end

  def sku
    "SKU-ST4NL3Y"
  end
end
