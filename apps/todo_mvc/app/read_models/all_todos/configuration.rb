module AllTodos
  class Todo < ApplicationRecord
    self.table_name = "all_todos"
  end
  private_constant :Todo

  def self.all
    Todo.order(created_at: :desc)
  end

  def self.active
    Todo.where(completed: false).order(created_at: :desc)
  end

  def self.completed
    Todo.where(completed: true).order(created_at: :desc)
  end

  def self.count
    Todo.count
  end

  def self.active_count
    Todo.where(completed: false).count
  end

  def self.completed_any?
    Todo.where(completed: true).exists?
  end

  class AddTodo
    def call(event)
      Todo.create!(uid: event.data.fetch(:todo_id))
    end
  end

  class SetDescription
    def call(event)
      Todo.find_by!(uid: event.data.fetch(:todo_id)).update!(description: event.data.fetch(:description))
    end
  end

  class UpdateDescription
    def call(event)
      Todo.find_by!(uid: event.data.fetch(:todo_id)).update!(description: event.data.fetch(:description))
    end
  end

  class MarkCompleted
    def call(event)
      Todo.find_by!(uid: event.data.fetch(:todo_id)).update!(completed: true)
    end
  end

  class MarkUncompleted
    def call(event)
      Todo.find_by!(uid: event.data.fetch(:todo_id)).update!(completed: false)
    end
  end

  class RemoveTodo
    def call(event)
      Todo.find_by!(uid: event.data.fetch(:todo_id)).destroy!
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(AddTodo.new, to: [::Todo::TodoAdded])
      event_store.subscribe(SetDescription.new, to: [::Todo::TodoDescriptionSet])
      event_store.subscribe(UpdateDescription.new, to: [::Todo::TodoDescriptionUpdated])
      event_store.subscribe(MarkCompleted.new, to: [::Todo::TodoCompleted])
      event_store.subscribe(MarkUncompleted.new, to: [::Todo::TodoUncompleted])
      event_store.subscribe(RemoveTodo.new, to: [::Todo::TodoCleared])
    end
  end
end
