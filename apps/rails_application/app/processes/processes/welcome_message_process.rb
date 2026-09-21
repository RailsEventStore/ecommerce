module Processes
  class WelcomeMessageProcess
    def initialize(event_store, command_bus)
      @event_store = event_store
      @command_bus = command_bus
    end

    def call(event)
      case event
      when Crm::CustomerRegistered
        @command_bus.call(
          Communication::SendMessage.new(
            SecureRandom.uuid,
            event.data.fetch(:customer_id),
            "Welcome to our platform!")
        )
      end
    end
  end
end
