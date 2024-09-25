# frozen_string_literal: true

def start_lifecycle_of_product_inventory_aggregate
  event_store = Rails.configuration.event_store
  repository = Infra::AggregateRootRepository.new(event_store)

  p 'Starting lifecycle of product inventory aggregate'

  ::Product.find_each do |product|
    ApplicationRecord.with_advisory_lock("change_stock_level_for_#{product.id}") do
      product_stream = event_store
                         .read
                         .stream("Inventory::Product$#{product.id}")
                         .of_type("Inventory::StockLevelMigrated")
                         .to_a

      p "Skipping product: #{product.id}"

      next if product_stream.any?

      repository.with_aggregate(Inventory::Product, product.id) do |aggregate|
        aggregate.migration_event(product.stock_level)
      end

      p "Migrated product: #{product.id}"

    end
  end

  p "Done"
end

start_lifecycle_of_product_inventory_aggregate

