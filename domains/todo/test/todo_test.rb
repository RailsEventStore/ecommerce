require_relative "test_helper"

module Todo
  class TodoTest < Test
    cover "Todo*"

    def test_add_todo
      todo_id = SecureRandom.uuid
      command_bus.call(AddTodo.new(todo_id: todo_id))

      assert_event_published(TodoAdded.new(data: { todo_id: todo_id }))
    end

    def test_cannot_add_same_todo_twice
      todo_id = SecureRandom.uuid
      command_bus.call(AddTodo.new(todo_id: todo_id))

      assert_raises(Todo::AlreadyExists) do
        command_bus.call(AddTodo.new(todo_id: todo_id))
      end
    end

    def test_set_todo_description
      todo_id = SecureRandom.uuid
      command_bus.call(AddTodo.new(todo_id: todo_id))
      command_bus.call(SetTodoDescription.new(todo_id: todo_id, description: "Buy milk"))

      assert_event_published(TodoDescriptionSet.new(data: { todo_id: todo_id, description: "Buy milk" }))
    end

    def test_cannot_set_description_for_nonexistent_todo
      todo_id = SecureRandom.uuid

      assert_raises(Todo::NotFound) do
        command_bus.call(SetTodoDescription.new(todo_id: todo_id, description: "Buy milk"))
      end
    end

    def test_update_todo_description
      todo_id = SecureRandom.uuid
      command_bus.call(AddTodo.new(todo_id: todo_id))
      command_bus.call(SetTodoDescription.new(todo_id: todo_id, description: "Buy milk"))
      command_bus.call(UpdateTodoDescription.new(todo_id: todo_id, description: "Buy bread"))

      assert_event_published(TodoDescriptionUpdated.new(data: { todo_id: todo_id, description: "Buy bread" }))
    end

    def test_cannot_update_description_for_nonexistent_todo
      todo_id = SecureRandom.uuid

      assert_raises(Todo::NotFound) do
        command_bus.call(UpdateTodoDescription.new(todo_id: todo_id, description: "Buy bread"))
      end
    end

    def test_complete_todo
      todo_id = SecureRandom.uuid
      command_bus.call(AddTodo.new(todo_id: todo_id))
      command_bus.call(CompleteTodo.new(todo_id: todo_id))

      assert_event_published(TodoCompleted.new(data: { todo_id: todo_id }))
    end

    def test_cannot_complete_nonexistent_todo
      todo_id = SecureRandom.uuid

      assert_raises(Todo::NotFound) do
        command_bus.call(CompleteTodo.new(todo_id: todo_id))
      end
    end

    def test_cannot_complete_already_completed_todo
      todo_id = SecureRandom.uuid
      command_bus.call(AddTodo.new(todo_id: todo_id))
      command_bus.call(CompleteTodo.new(todo_id: todo_id))

      assert_raises(Todo::AlreadyCompleted) do
        command_bus.call(CompleteTodo.new(todo_id: todo_id))
      end
    end

    def test_uncomplete_todo
      todo_id = SecureRandom.uuid
      command_bus.call(AddTodo.new(todo_id: todo_id))
      command_bus.call(CompleteTodo.new(todo_id: todo_id))
      command_bus.call(UncompleteTodo.new(todo_id: todo_id))

      assert_event_published(TodoUncompleted.new(data: { todo_id: todo_id }))
    end

    def test_cannot_uncomplete_nonexistent_todo
      todo_id = SecureRandom.uuid

      assert_raises(Todo::NotFound) do
        command_bus.call(UncompleteTodo.new(todo_id: todo_id))
      end
    end

    def test_cannot_uncomplete_not_completed_todo
      todo_id = SecureRandom.uuid
      command_bus.call(AddTodo.new(todo_id: todo_id))

      assert_raises(Todo::NotCompleted) do
        command_bus.call(UncompleteTodo.new(todo_id: todo_id))
      end
    end

    def test_clear_todo
      todo_id = SecureRandom.uuid
      command_bus.call(AddTodo.new(todo_id: todo_id))
      command_bus.call(ClearTodo.new(todo_id: todo_id))

      assert_event_published(TodoCleared.new(data: { todo_id: todo_id }))
    end

    def test_cannot_clear_nonexistent_todo
      todo_id = SecureRandom.uuid

      assert_raises(Todo::NotFound) do
        command_bus.call(ClearTodo.new(todo_id: todo_id))
      end
    end

    private

    def assert_event_published(expected_event)
      actual_event = event_store.read.of_type(expected_event.class).last
      assert_equal(expected_event.data, actual_event.data)
      assert_equal(expected_event.class, actual_event.class)
    end
  end
end
