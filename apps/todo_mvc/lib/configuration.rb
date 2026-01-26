require_relative "../../../domains/todo/lib/todo"
require_relative "../../../infra/lib/infra"

class Configuration
  def call(event_store, command_bus)
    enable_res_infra_event_linking(event_store)
    enable_all_todos_read_model(event_store)

    Todo::Configuration.new.call(event_store, command_bus)
  end

  private

  def enable_res_infra_event_linking(event_store)
    [
      RailsEventStore::LinkByEventType.new,
      RailsEventStore::LinkByCorrelationId.new,
      RailsEventStore::LinkByCausationId.new
    ].each { |h| event_store.subscribe_to_all_events(h) }
  end

  def enable_all_todos_read_model(event_store)
    AllTodos::Configuration.new.call(event_store)
  end
end
