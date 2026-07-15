require_relative "../../../domains/social/lib/social"
require_relative "../../../domains/authentication/lib/authentication"
require_relative "../../../infra/lib/infra"
require_relative "../app/processes/timeline_delivery_process"

class Configuration
  def call(event_store, command_bus)
    enable_res_infra_event_linking(event_store)
    enable_public_feed_read_model(event_store)
    enable_accounts_read_model(event_store)
    enable_follows_read_model(event_store)
    enable_personal_timeline_read_model(event_store)
    enable_profile_read_model(event_store)
    enable_timeline_delivery_process(event_store, command_bus)

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

  def enable_public_feed_read_model(event_store)
    PublicFeed::Configuration.new.call(event_store)
  end

  def enable_accounts_read_model(event_store)
    Accounts::Configuration.new.call(event_store)
  end

  def enable_follows_read_model(event_store)
    Follows::Configuration.new.call(event_store)
  end

  def enable_personal_timeline_read_model(event_store)
    PersonalTimeline::Configuration.new.call(event_store)
  end

  def enable_profile_read_model(event_store)
    Profile::Configuration.new.call(event_store)
  end

  def enable_timeline_delivery_process(event_store, command_bus)
    event_store.subscribe(
      TimelineDeliveryProcess.new(event_store, command_bus),
      to: TimelineDeliveryProcess.subscribed_events
    )
  end
end
