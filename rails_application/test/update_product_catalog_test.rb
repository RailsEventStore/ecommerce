# frozen_string_literal: true

require 'test_helper'

class UpdateProductCatalogTest < InMemoryTestCase
  def test_happy_path
    product = Product.create!(name: 'Test Product', price: 10, vat_rate: 23, sku: 'test', stock_level: 0)

    stock_level_increased = Inventory::StockLevelIncreased.new(data: { id: product.id, quantity: 10 })
    stock_level_increased_second_time = Inventory::StockLevelIncreased.new(data: { id: product.id, quantity: 10 })
    event_store.append(stock_level_increased, stream_name: "Inventory::Product$#{product.id}")
    event_store.append(stock_level_increased_second_time, stream_name: "Inventory::Product$#{product.id}")

    Inventory::UpdateProductCatalog.new.call(stock_level_increased)
    Inventory::UpdateProductCatalog.new.call(stock_level_increased_second_time)

    assert_equal 20, Inventory::ProductCatalog.find_by(product_id: product.id).stock_level
  end

  def test_life_is_brutal_and_full_of_traps
    product = Product.create!(name: 'Test Product', price: 10, vat_rate: 23, sku: 'test', stock_level: 0)

    stock_level_increased = Inventory::StockLevelIncreased.new(data: { id: product.id, quantity: 10 })
    event_store.append(stock_level_increased, stream_name: "Inventory::Product$#{product.id}")

    Inventory::UpdateProductCatalog.new.call(stock_level_increased)
    Inventory::UpdateProductCatalog.new.call(stock_level_increased)

    assert_equal 10, Inventory::ProductCatalog.find_by(product_id: product.id).stock_level
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end