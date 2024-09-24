# frozen_string_literal: true

module Inventory
  class ProductService

    def initialize
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def decrement_stock_level(product_id)
      ApplicationRecord.with_advisory_lock("change_stock_level_for_#{product_id}") do
        product = ::Product.find(product_id)
        product_stream = event_store.read.stream("Inventory::Product$#{product_id}").to_a

        if product_stream.any? { |event| event.event_type == "Inventory::StockLevelMigrated" }
          with_inventory_product(product_id) do |aggregate|
            aggregate.withdraw(1)
          end
        else
          with_inventory_product(product_id) do |aggregate|
            aggregate.migration_event(product.stock_level)
            aggregate.withdraw(1)
          end
        end
        product.decrement!(:stock_level)
      end
    end

    def increment_stock_level(product_id)
      ApplicationRecord.with_advisory_lock("change_stock_level_for_#{product_id}") do
        product = ::Product.find(product_id)
        product_stream = event_store.read.stream("Inventory::Product$#{product_id}").to_a

        if product_stream.any? { |event| event.event_type == "Inventory::StockLevelMigrated" }
          with_inventory_product(product_id) do |aggregate|
            aggregate.supply(1)
          end
        else
          with_inventory_product(product_id) do |aggregate|
            aggregate.migration_event(product.stock_level)
            aggregate.supply(1)
          end
        end
        product.increment!(:stock_level)
      end
    end

    def supply(product_id, quantity)
      ApplicationRecord.with_advisory_lock("change_stock_level_for_#{product_id}") do
        product = ::Product.find(product_id)
        product.stock_level == nil ? product.stock_level = quantity : product.stock_level += quantity
        product_stream = event_store.read.stream("Inventory::Product$#{product_id}").to_a

        if product_stream.any? { |event| event.event_type == "Inventory::StockLevelMigrated" }
          with_inventory_product(product_id) do |aggregate|
            aggregate.supply(quantity)
          end
        else
          with_inventory_product(product_id) do |aggregate|
            aggregate.migration_event(product.stock_level)
          end
        end
        product.save!
      end
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def with_inventory_product(product_id)
      @repository.with_aggregate(Inventory::Product, product_id) do |product|
        yield(product)
      end
    end
  end
end
