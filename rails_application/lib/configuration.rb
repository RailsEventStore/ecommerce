require_relative "../../infra/lib/infra"

VatRate = Struct.new(:code, :rate)

class Configuration
  def call(event_store, command_bus)
    enable_res_infra_event_linking(event_store)

    event_store.subscribe(UpdateProductStockLevel, to: [Inventory::StockLevelIncreased, Inventory::StockLevelDecreased])
  end

  def self.available_vat_rates
    [
      VatRate.new("23", 23),
      VatRate.new("10", 10),
    ]
  end

  private

  def enable_res_infra_event_linking(event_store)
    [
      RailsEventStore::LinkByEventType.new,
      RailsEventStore::LinkByCorrelationId.new,
      RailsEventStore::LinkByCausationId.new
    ].each { |h| event_store.subscribe_to_all_events(h) }
  end
end
