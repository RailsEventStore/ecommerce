module Processes
  class WelcomeMessageProcess
    def initialize(event_store, command_bus)
      @event_store = event_store
      @command_bus = command_bus
    end

    def call(event)
      case event
      when Crm::CustomerRegistered
        ClientInbox::Message.create(client_uid: event.data.fetch(:customer_id), title: "Welcome to our platform!")
      end
    end
  end
end