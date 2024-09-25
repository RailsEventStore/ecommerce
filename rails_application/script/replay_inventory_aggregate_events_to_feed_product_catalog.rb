# frozen_string_literal: true

def replay_inventory_aggregate_events_to_feed_product_catalog
  event_store = Rails.configuration.event_store
  ::Product.find_each do |product|
    pp "Replaying events for product: #{product.id}"

    event_store.read.stream("Inventory::Product$#{product.id}").each do |event|
      Inventory::UpdateProductCatalog.new.call(event)
    end
  end
end

replay_inventory_aggregate_events_to_feed_product_catalog
