require "infra"

module Communication
  class Configuration

    def call(event_store, command_bus)
      command_bus.register(SendMessage, OnSendMessage.new(event_store))
      command_bus.register(ReadMessage, OnReadMessage.new(event_store))
    end
  end

  class SendMessage < Infra::Command
    attribute :message_id, Infra::Types::UUID
    attribute :receiver_id, Infra::Types::UUID
    attribute :message, Infra::Types::String
  end

  class MessageSent < Infra::Event
    attribute :message_id, Infra::Types::UUID
    attribute :receiver_id, Infra::Types::UUID
    attribute :message, Infra::Types::String
  end

  class ReadMessage < Infra::Command
    attribute :message_id, Infra::Types::UUID
  end

  class MessageRead < Infra::Event
    attribute :message_id, Infra::Types::UUID
  end

  class OnSendMessage
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Message, command.message_id) do |message|
        message._send(command.receiver_id, command.message)
      end
    end
  end

  class OnReadMessage
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Message, command.message_id) do |message|
        message.read(command.message_id)
      end
    end
  end

  class Message
    include AggregateRoot

    def initialize(id)
      @id = id
    end

    def _send(receiver_id, message)
      apply MessageSent.new(
        data: {
          message_id: @id,
          receiver_id: receiver_id,
          message: message
        }
      )
    end

    def read(message_id)
      apply MessageRead.new(data: { message_id: message_id })
    end

    def apply_message_sent(_)
    end

    def apply_message_read(_)
    end
  end
end
