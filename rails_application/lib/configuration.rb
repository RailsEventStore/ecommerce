require_relative "../../infra/lib/infra"

VatRate = Struct.new(:code, :rate)

class Configuration
  def call(event_store, command_bus)
    enable_res_infra_event_linking(event_store)

    event_store.subscribe(
      BuildMostRecentProductsInUnfinishedOrders,
      to: [
        ProductCatalog::ProductCreated,
        ProductCatalog::ProductNameChanged,
        Ordering::OrderExpired,
        Ordering::ItemAdded,
        Ordering::OrderPaid,
        Ordering::OrderSubmitted
      ]
    )
    event_store.subscribe(
      Inventory::UpdateProductCatalog,
      to: [Inventory::StockLevelIncreased, Inventory::StockLevelDecreased]
    )

    event_store.subscribe(
      SendEmail,
      to: [Ordering::OrderPaid, Invoicing::InvoiceGenerated]
    )
  end

  def self.available_vat_rates
    [VatRate.new("23", 23), VatRate.new("10", 10)]
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
