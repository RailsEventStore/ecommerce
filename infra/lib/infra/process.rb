module Infra
  class Process
    def initialize(event_store, command_bus)
      @event_store = event_store
      @command_bus = command_bus
    end

    def call(event_name, event_data_keys, command, command_data_keys)
      @event_store.subscribe(
        ->(event) do
          @command_bus.call(
            command.new(
              Hash[
                command_data_keys.zip(
                  event_data_keys.map { |key| event.data.fetch(key) }
                )
              ]
            )
          )
        end,
        to: [event_name]
      )
    end
  end
end