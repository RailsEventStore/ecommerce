require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/communication"

module Communication
  class Test < Infra::InMemoryTest
    def before_setup
      super()
      Configuration.new.call(event_store, command_bus)
    end

    private

    def send_message
      run_command(SendMessage.new(message_id: message_id, receiver_id: receiver_id, message: message_content))
    end

    def message_content
      "Hello, this is a test message."
    end

    def receiver_id
      @receiver_id ||= SecureRandom.uuid
    end

    def message_id
      @message_id ||= SecureRandom.uuid
    end

  end
end
