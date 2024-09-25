# frozen_string_literal: true

module Inventory
  class ProductService

    def initialize
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def decrement_stock_level(command)
      product_id = command.product_id
      ApplicationRecord.transaction do
        product = ::Product.find(product_id)
        with_inventory_product(product_id) do |aggregate|
          aggregate.withdraw(1)
        end
        product.decrement!(:stock_level)
      end
    end

    def increment_stock_level(command)
      product_id = command.product_id
      ApplicationRecord.transaction do
        product = ::Product.find(product_id)
        with_inventory_product(product_id) do |aggregate|
          aggregate.supply(1)
        end
        product.increment!(:stock_level)
      end
    end

    def supply(command)
      product_id = command.product_id
      quantity = command.quantity

      ApplicationRecord.transaction do
        product = ::Product.find(product_id)
        product.stock_level == nil ? product.stock_level = quantity : product.stock_level += quantity
        with_inventory_product(product_id) do |aggregate|
          aggregate.supply(product.stock_level)
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
