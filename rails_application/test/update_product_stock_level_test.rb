# frozen_string_literal: true

require 'test_helper'

class UpdateProductStockLevelTest < InMemoryTestCase
  def test_happy_path
    product = Product.create!(name: 'Test Product', price: 10, vat_rate: 23, sku: 'test', stock_level: 0)

    stock_level_increased = Inventory::StockLevelIncreased.new(data: { id: product.id, quantity: 10 })
    stock_level_increased_second_time = Inventory::StockLevelIncreased.new(data: { id: product.id, quantity: 10 })
    event_store.append(stock_level_increased, stream_name: "Inventory::Product$#{product.id}")
    event_store.append(stock_level_increased_second_time, stream_name: "Inventory::Product$#{product.id}")
    UpdateProductStockLevel.new.call(stock_level_increased)
    UpdateProductStockLevel.new.call(stock_level_increased_second_time)

    assert_equal 20, product.reload.stock_level
  end

  def test_life_is_brutal_and_full_of_traps
    product = Product.create!(name: 'Test Product', price: 10, vat_rate: 23, sku: 'test', stock_level: 0)

    stock_level_increased = Inventory::StockLevelIncreased.new(data: { id: product.id, quantity: 10 })
    event_store.append(stock_level_increased, stream_name: "Inventory::Product$#{product.id}")
    UpdateProductStockLevel.new.call(stock_level_increased)
    UpdateProductStockLevel.new.call(stock_level_increased)

    assert_equal 10, product.reload.stock_level
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end
