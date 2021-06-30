class Cqrs
  def initialize(event_store, command_bus)
    @event_store = event_store
    @command_bus = command_bus
  end

  def subscribe(subscriber, events)
    @event_store.subscribe(subscriber, to: events)
  end

  def register(command_handler, command)
    @command_bus.register(command_handler, command)
  end

  def run(command)
    @command_bus.call(command)
  end
end
