require_relative "../test_helper"

module AllTodos
  class AllTodosTest < InMemoryRESTestCase
    cover "AllTodos*"

    def test_adds_todo_on_todo_added
      todo_id = SecureRandom.uuid
      event_store.publish(::Todo::TodoAdded.new(data: { todo_id: todo_id }))

      assert_equal(1, AllTodos.count)
      assert_equal(todo_id, AllTodos.all.first.uid)
      assert_equal(false, AllTodos.all.first.completed)
      assert_nil(AllTodos.all.first.description)
    end

    def test_sets_description_on_todo_description_set
      todo_id = SecureRandom.uuid
      event_store.publish(::Todo::TodoAdded.new(data: { todo_id: todo_id }))
      event_store.publish(::Todo::TodoDescriptionSet.new(data: { todo_id: todo_id, description: "Buy milk" }))

      assert_equal("Buy milk", AllTodos.all.first.description)
    end

    def test_updates_description_on_todo_description_updated
      todo_id = SecureRandom.uuid
      event_store.publish(::Todo::TodoAdded.new(data: { todo_id: todo_id }))
      event_store.publish(::Todo::TodoDescriptionSet.new(data: { todo_id: todo_id, description: "Buy milk" }))
      event_store.publish(::Todo::TodoDescriptionUpdated.new(data: { todo_id: todo_id, description: "Buy bread" }))

      assert_equal("Buy bread", AllTodos.all.first.description)
    end

    def test_marks_completed_on_todo_completed
      todo_id = SecureRandom.uuid
      event_store.publish(::Todo::TodoAdded.new(data: { todo_id: todo_id }))
      event_store.publish(::Todo::TodoCompleted.new(data: { todo_id: todo_id }))

      assert_equal(true, AllTodos.all.first.completed)
    end

    def test_marks_uncompleted_on_todo_uncompleted
      todo_id = SecureRandom.uuid
      event_store.publish(::Todo::TodoAdded.new(data: { todo_id: todo_id }))
      event_store.publish(::Todo::TodoCompleted.new(data: { todo_id: todo_id }))
      event_store.publish(::Todo::TodoUncompleted.new(data: { todo_id: todo_id }))

      assert_equal(false, AllTodos.all.first.completed)
    end

    def test_removes_todo_on_todo_cleared
      todo_id = SecureRandom.uuid
      event_store.publish(::Todo::TodoAdded.new(data: { todo_id: todo_id }))
      event_store.publish(::Todo::TodoCleared.new(data: { todo_id: todo_id }))

      assert_equal(0, AllTodos.count)
    end

    def test_returns_todos_in_reverse_chronological_order
      todo_id_1 = SecureRandom.uuid
      todo_id_2 = SecureRandom.uuid
      event_store.publish(::Todo::TodoAdded.new(data: { todo_id: todo_id_1 }))
      event_store.publish(::Todo::TodoAdded.new(data: { todo_id: todo_id_2 }))

      assert_equal(todo_id_2, AllTodos.all.first.uid)
      assert_equal(todo_id_1, AllTodos.all.last.uid)
    end

    def test_count_returns_total_number_of_todos
      assert_equal(0, AllTodos.count)

      event_store.publish(::Todo::TodoAdded.new(data: { todo_id: SecureRandom.uuid }))
      assert_equal(1, AllTodos.count)

      event_store.publish(::Todo::TodoAdded.new(data: { todo_id: SecureRandom.uuid }))
      assert_equal(2, AllTodos.count)
    end

    def test_all_returns_empty_array_when_no_todos
      assert_equal([], AllTodos.all.to_a)
    end

    def test_active_returns_only_active_todos
      active_id = SecureRandom.uuid
      completed_id = SecureRandom.uuid

      event_store.publish(::Todo::TodoAdded.new(data: { todo_id: active_id }))
      event_store.publish(::Todo::TodoAdded.new(data: { todo_id: completed_id }))
      event_store.publish(::Todo::TodoCompleted.new(data: { todo_id: completed_id }))

      assert_equal(1, AllTodos.active.count)
      assert_equal(active_id, AllTodos.active.first.uid)
    end

    def test_completed_returns_only_completed_todos
      active_id = SecureRandom.uuid
      completed_id = SecureRandom.uuid

      event_store.publish(::Todo::TodoAdded.new(data: { todo_id: active_id }))
      event_store.publish(::Todo::TodoAdded.new(data: { todo_id: completed_id }))
      event_store.publish(::Todo::TodoCompleted.new(data: { todo_id: completed_id }))

      assert_equal(1, AllTodos.completed.count)
      assert_equal(completed_id, AllTodos.completed.first.uid)
    end

    def test_active_count_returns_number_of_active_todos
      active_id_1 = SecureRandom.uuid
      active_id_2 = SecureRandom.uuid
      completed_id = SecureRandom.uuid

      event_store.publish(::Todo::TodoAdded.new(data: { todo_id: active_id_1 }))
      event_store.publish(::Todo::TodoAdded.new(data: { todo_id: active_id_2 }))
      event_store.publish(::Todo::TodoAdded.new(data: { todo_id: completed_id }))
      event_store.publish(::Todo::TodoCompleted.new(data: { todo_id: completed_id }))

      assert_equal(2, AllTodos.active_count)
    end

    def test_completed_any_returns_true_when_completed_todos_exist
      completed_id = SecureRandom.uuid

      event_store.publish(::Todo::TodoAdded.new(data: { todo_id: completed_id }))
      event_store.publish(::Todo::TodoCompleted.new(data: { todo_id: completed_id }))

      assert_equal(true, AllTodos.completed_any?)
    end

    def test_completed_any_returns_false_when_no_completed_todos
      active_id = SecureRandom.uuid

      event_store.publish(::Todo::TodoAdded.new(data: { todo_id: active_id }))

      assert_equal(false, AllTodos.completed_any?)
    end
  end
end
