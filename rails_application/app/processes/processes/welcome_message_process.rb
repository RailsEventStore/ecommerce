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
            message_id: SecureRandom.uuid,
            receiver_id: event.data.fetch(:customer_id),
            message: "Welcome to our platform!")
        )
      end
    end
  end
end