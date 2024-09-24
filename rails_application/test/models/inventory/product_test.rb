# frozen_string_literal: true

require 'test_helper'

module Inventory
  class ProductTest < Infra::InMemoryTest
    def test_supply
      product_id = 1024

      assert_events(stream_name(product_id), StockLevelIncreased.new(data: { id: product_id, quantity: 10 })) do
        with_aggregate(product_id) do |product|
          product.supply(10)
        end
      end
    end

    def test_withdraw
      product_id = 1024

      assert_events(stream_name(product_id),
                    StockLevelIncreased.new(data: { id: product_id, quantity: 10 }),
                    StockLevelDecreased.new(data: { id: product_id, quantity: 5 })
      ) do
        with_aggregate(product_id) do |product|
          product.supply(10)
          product.withdraw(5)
        end
      end
    end

    def test_withdraw_when_not_enough_stock_is_not_allowed
      product_id = 1024

      assert_nothing_published_within do
        assert_raises("Not enough stock") do
          with_aggregate(product_id) do |product|
            product.withdraw(10)
          end
        end
      end
    end

    private

    def stream_name(product_id)
      "Inventory::Product$#{product_id}"
    end

    def with_aggregate(product_id)
      Infra::AggregateRootRepository.new(event_store).with_aggregate(Product, product_id) do |product|
        yield product
      end
    end
  end
end