require 'infra'
require_relative 'todo/todo'

module Todo
  class Configuration
    def call(event_store, command_bus)
      command_bus.register(AddTodo, AddTodoHandler.new(event_store))
      command_bus.register(SetTodoDescription, SetTodoDescriptionHandler.new(event_store))
      command_bus.register(UpdateTodoDescription, UpdateTodoDescriptionHandler.new(event_store))
      command_bus.register(CompleteTodo, CompleteTodoHandler.new(event_store))
      command_bus.register(UncompleteTodo, UncompleteTodoHandler.new(event_store))
      command_bus.register(ClearTodo, ClearTodoHandler.new(event_store))
    end
  end
end