require_relative "../../../infra/lib/infra"
require_relative "../../../domains/underwriting/lib/underwriting"
require_relative "../../../domains/policies/lib/policies"
require_relative "../../../domains/claims/lib/claims"
require_relative "../../../domains/payments/lib/payments"

class Configuration
  def call(event_store, command_bus)
    enable_res_infra_event_linking(event_store)

    Underwriting::Configuration.new.call(event_store, command_bus)
    Policies::Configuration.new.call(event_store, command_bus)
    Claims::Configuration.new(Rails.configuration.payout_gateway).call(event_store, command_bus)
    Payments::Configuration.new(Rails.configuration.payment_gateway).call(event_store, command_bus)

    Processes::Configuration.new.call(event_store, command_bus)

    enable_applications_read_model(event_store)
  end

  private

  def enable_applications_read_model(event_store)
    Applications::Configuration.new.call(event_store)
  end

  def enable_res_infra_event_linking(event_store)
    [
      RailsEventStore::LinkByEventType.new,
      RailsEventStore::LinkByCorrelationId.new,
      RailsEventStore::LinkByCausationId.new
    ].each { |h| event_store.subscribe_to_all_events(h) }
  end
end
