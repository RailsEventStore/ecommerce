require "infra"

module Communication
  class Configuration

    def call(event_store, command_bus)
      command_bus.register(SendMessage, OnSendMessage.new(event_store))
      command_bus.register(ReadMessage, OnReadMessage.new(event_store))
    end
  end

  class SendMessage
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

    attr_reader :message_id, :receiver_id, :message

    def initialize(message_id, receiver_id, message)
      @message_id = message_id
      @receiver_id = receiver_id
      @message = message
      valid = UUID.match?(@message_id) && UUID.match?(@receiver_id) && @message.is_a?(String)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class MessageSent < Infra::Event
    attribute :message_id, Infra::Types::UUID
    attribute :receiver_id, Infra::Types::UUID
    attribute :message, Infra::Types::String
  end

  class ReadMessage
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

    attr_reader :message_id

    def initialize(message_id)
      @message_id = message_id
      valid = UUID.match?(@message_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
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

    on MessageSent do |_|
    end

    on MessageRead do |_|
    end
  end
end
