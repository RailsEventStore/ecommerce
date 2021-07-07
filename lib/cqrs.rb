class Cqrs
  def initialize(event_store, command_bus)
    @event_store = event_store
    @command_bus = command_bus
    @commands_to_events = {}
  end

  def subscribe(subscriber, events)
    @event_store.subscribe(subscriber, to: events)
  end

  def register_command(command_handler, command, events)
    @commands_to_events[command] = events
    @command_bus.register(command_handler, command)
  end

  def register(command_handler, command)
    @command_bus.register(command_handler, command)
  end

  def run(command)
    @command_bus.call(command)
  end

  def to_hash
    @commands_to_events
  end
end
