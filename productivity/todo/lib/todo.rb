require 'infra'
require_relative 'todo/todo'

module Todo
  class Configuration
    def call(event_store, command_bus)
      command_bus.register(AddTask, AddTaskHandler.new(event_store))
    end
  end
end