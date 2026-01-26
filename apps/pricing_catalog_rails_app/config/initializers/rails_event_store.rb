require_relative "../../../../domains/pricing/lib/pricing"
require_relative "../../../../domains/product_catalog//lib/product_catalog"
require_relative "../../../../infra/lib/infra"
require "rails_event_store"
require "arkency/command_bus"
require_relative "../../app/public/read_models/public_catalog/public_catalog"
require_relative "../../app/admin/read_models/admin_catalog/admin_catalog"

Rails.configuration.to_prepare do
  Rails.configuration.event_store = Infra::EventStore.main
  Rails.configuration.command_bus = Arkency::CommandBus.new
  Configuration.new.call(Rails.configuration.event_store, Rails.configuration.command_bus)
end

class Configuration
  def call(event_store, command_bus)
    enable_res_infra_event_linking(event_store)
    [
      Pricing::Configuration.new,
      ProductCatalog::Configuration.new,
    ].each { |c| c.call(event_store, command_bus) }
    PublicCatalog::Configuration.new.call(event_store)
    AdminCatalog::Configuration.new.call(event_store)

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

