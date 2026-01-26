module Todo
  class AddTodo < Infra::Command
    attribute :todo_id, Infra::Types::UUID
  end

  class SetTodoDescription < Infra::Command
    attribute :todo_id, Infra::Types::UUID
    attribute :description, Infra::Types::String
  end

  class UpdateTodoDescription < Infra::Command
    attribute :todo_id, Infra::Types::UUID
    attribute :description, Infra::Types::String
  end

  class CompleteTodo < Infra::Command
    attribute :todo_id, Infra::Types::UUID
  end

  class UncompleteTodo < Infra::Command
    attribute :todo_id, Infra::Types::UUID
  end

  class ClearTodo < Infra::Command
    attribute :todo_id, Infra::Types::UUID
  end

  class TodoAdded < Infra::Event
    attribute :todo_id, Infra::Types::UUID
  end

  class TodoDescriptionSet < Infra::Event
    attribute :todo_id, Infra::Types::UUID
    attribute :description, Infra::Types::String
  end

  class TodoDescriptionUpdated < Infra::Event
    attribute :todo_id, Infra::Types::UUID
    attribute :description, Infra::Types::String
  end

  class TodoCompleted < Infra::Event
    attribute :todo_id, Infra::Types::UUID
  end

  class TodoUncompleted < Infra::Event
    attribute :todo_id, Infra::Types::UUID
  end

  class TodoCleared < Infra::Event
    attribute :todo_id, Infra::Types::UUID
  end

  class Todo
    include AggregateRoot

    AlreadyExists = Class.new(StandardError)
    NotFound = Class.new(StandardError)
    AlreadyCompleted = Class.new(StandardError)
    NotCompleted = Class.new(StandardError)

    def initialize(id)
      @id = id
      @exists = false
      @completed = false
    end

    def add(todo_id)
      raise AlreadyExists if @exists
      apply(TodoAdded.new(data: { todo_id: todo_id }))
    end

    def set_description(description)
      raise NotFound unless @exists
      apply(TodoDescriptionSet.new(data: { todo_id: @id, description: description }))
    end

    def update_description(description)
      raise NotFound unless @exists
      apply(TodoDescriptionUpdated.new(data: { todo_id: @id, description: description }))
    end

    def complete
      raise NotFound unless @exists
      raise AlreadyCompleted if @completed
      apply(TodoCompleted.new(data: { todo_id: @id }))
    end

    def uncomplete
      raise NotFound unless @exists
      raise NotCompleted unless @completed
      apply(TodoUncompleted.new(data: { todo_id: @id }))
    end

    def clear
      raise NotFound unless @exists
      apply(TodoCleared.new(data: { todo_id: @id }))
    end

    private

    on TodoAdded do |event|
      @exists = true
    end

    on TodoDescriptionSet do |event|
    end

    on TodoDescriptionUpdated do |event|
    end

    on TodoCompleted do |event|
      @completed = true
    end

    on TodoUncompleted do |event|
      @completed = false
    end

    on TodoCleared do |event|
    end
  end

  class AddTodoHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Todo, command.todo_id) do |todo|
        todo.add(command.todo_id)
      end
    end
  end

  class SetTodoDescriptionHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Todo, command.todo_id) do |todo|
        todo.set_description(command.description)
      end
    end
  end

  class UpdateTodoDescriptionHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Todo, command.todo_id) do |todo|
        todo.update_description(command.description)
      end
    end
  end

  class CompleteTodoHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Todo, command.todo_id) do |todo|
        todo.complete
      end
    end
  end

  class UncompleteTodoHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Todo, command.todo_id) do |todo|
        todo.uncomplete
      end
    end
  end

  class ClearTodoHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Todo, command.todo_id) do |todo|
        todo.clear
      end
    end
  end
end
