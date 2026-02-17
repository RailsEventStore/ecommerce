require_relative "../../../domains/crm/lib/crm"
require_relative "../../../infra/lib/infra"

class Configuration
  def call(event_store, command_bus)
    enable_res_infra_event_linking(event_store)

    Crm::Configuration.new.call(event_store, command_bus)
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
