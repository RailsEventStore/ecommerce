require "test_helper"
require_relative "../../script/start_lifecycle_of_product_inventory_aggregate"

class MigrationTest < InMemoryRESIntegrationTestCase
  def setup
    super
  end

  def test_migration_applies_only_to_prodcuts_that_dont_have_migration_event_in_stream
    product_1_sku = "SKU-ST4NL3Y-1"
    product_2_sku = "SKU-ST4NL3Y-2"
    create_product(sku: product_1_sku)
    create_product(sku: product_2_sku)
    product_1_id = Product.find_by(sku: product_1_sku).id
    product_2_id =  Product.find_by(sku: product_2_sku).id

    increase_stock_level_by_10(product_1_id)
    product_1_stream = event_store.read.stream("Inventory::Product$#{product_1_id}").to_a
    assert product_1_stream.map(&:event_type) == ["Inventory::StockLevelMigrated"]
    product_2_stream = event_store.read.stream("Inventory::Product$#{product_2_id}").to_a
    assert product_2_stream.empty?

    start_lifecycle_of_product_inventory_aggregate
    product_2_stream = event_store.read.stream("Inventory::Product$#{product_2_id}").to_a
    assert product_2_stream.map(&:event_type) == ["Inventory::StockLevelMigrated"]
  end

  private

  def event_store
    Rails.configuration.event_store
  end

  def increase_stock_level_by_10(product_id)
    post "/products/#{product_id}/supplies", params: { product_id: product_id, quantity: 10 }
  end

  def create_product(sku:)
    post "/products", params: { product: { name: "Stanley Cup", price: 100, vat_rate: 23, sku: } }
  end

  def sku
    "SKU-ST4NL3Y"
  end
end
