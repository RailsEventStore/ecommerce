# frozen_string_literal: true

require 'test_helper'
require_relative '../../script/replay_inventory_aggregate_events_to_feed_product_catalog'

class FeedProductCatalogTest < InMemoryRESIntegrationTestCase
  def test_feed_product_catalog
    product = Product.create!(name: 'Test Product', price: 10, vat_rate: 23, sku: 'test')

    event_store.append(Inventory::StockLevelIncreased.new(data: { id: product.id, quantity: 10 }), stream_name: "Inventory::Product$#{product.id}")

    replay_inventory_aggregate_events_to_feed_product_catalog

    product_catalog = Inventory::ProductCatalog.find_by(product_id: product.id)
    assert_equal 10, product_catalog.stock_level
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end
