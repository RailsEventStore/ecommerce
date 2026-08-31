# auto_register: false
# frozen_string_literal: true

module HanamiApplication
  class TransactionalCommandBus
    def initialize(command_bus, connection)
      @command_bus = command_bus
      @connection = connection
    end

    def call(command)
      @connection.transaction { @command_bus.call(command) }
    end
  end
end
