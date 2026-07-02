require_relative "../../../domains/social/lib/social"
require_relative "../../../domains/authentication/lib/authentication"
require_relative "../../../infra/lib/infra"

class Configuration
  def call(event_store, command_bus)
    enable_res_infra_event_linking(event_store)
    enable_feed_read_model(event_store)
    enable_accounts_read_model(event_store)

    Social::Configuration.new.call(event_store, command_bus)
    Authentication::Configuration.new.call(event_store, command_bus)
  end

  private

  def enable_res_infra_event_linking(event_store)
    [
      RailsEventStore::LinkByEventType.new,
      RailsEventStore::LinkByCorrelationId.new,
      RailsEventStore::LinkByCausationId.new
    ].each { |h| event_store.subscribe_to_all_events(h) }
  end

  def enable_feed_read_model(event_store)
    Feed::Configuration.new.call(event_store)
  end

  def enable_accounts_read_model(event_store)
    Accounts::Configuration.new.call(event_store)
  end
end
