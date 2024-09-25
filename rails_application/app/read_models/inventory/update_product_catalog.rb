# frozen_string_literal: true

module Inventory
  class UpdateProductCatalog
    def call(event)
      product_catalog = ProductCatalog.find_or_initialize_by(product_id: event.data[:id])

      checkpoint = product_catalog.checkpoint

      product_stream = event_store.read.stream("Inventory::Product$#{product_catalog.product_id}")
      product_stream = product_stream.from(checkpoint) if checkpoint

      product_stream.each do |event|
        case event
        when Inventory::StockLevelIncreased
          product_catalog.increment!(:stock_level, event.data[:quantity])
        when Inventory::StockLevelDecreased
          product_catalog.decrement!(:stock_level, event.data[:quantity])
        when Inventory::StockLevelMigrated
          product_catalog.stock_level = event.data[:quantity]
        end
        product_catalog.checkpoint = event.event_id
      end

      product_catalog.save!
    end

    private

    def event_store
      Rails.configuration.event_store
    end
  end
end