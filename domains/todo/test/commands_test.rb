require_relative "test_helper"

module Todo
  class CommandsTest < Test
    cover "Todo*"

    TODO_ID = "123e4567-e89b-42d3-a456-426614174000"

    def test_exposes_attributes
      command = SetTodoDescription.new(TODO_ID, "Buy milk")

      assert_equal(TODO_ID, command.todo_id)
      assert_equal("Buy milk", command.description)
      assert_equal(TODO_ID, UpdateTodoDescription.new(TODO_ID, "Buy bread").todo_id)
    end

    def test_rejects_invalid_todo_id
      constructors.each do |constructor|
        assert_raises(Infra::Command::Invalid) { constructor.call("not-a-uuid") }
        assert_raises(Infra::Command::Invalid) { constructor.call(Object.new) }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-12d3-a456-426614174000") }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-42d3-7456-426614174000") }
      end
    end

    def test_rejects_invalid_descriptions
      assert_raises(Infra::Command::Invalid) { SetTodoDescription.new(TODO_ID, Object.new) }
      assert_raises(Infra::Command::Invalid) { UpdateTodoDescription.new(TODO_ID, Object.new) }
    end

    def test_accepts_string_subclasses
      description = Class.new(String).new("Buy milk")

      assert_equal(description, SetTodoDescription.new(TODO_ID, description).description)
      assert_equal(description, UpdateTodoDescription.new(TODO_ID, description).description)
    end

    private

    def constructors
      [
        ->(todo_id) { AddTodo.new(todo_id) },
        ->(todo_id) { SetTodoDescription.new(todo_id, "Buy milk") },
        ->(todo_id) { UpdateTodoDescription.new(todo_id, "Buy bread") },
        ->(todo_id) { CompleteTodo.new(todo_id) },
        ->(todo_id) { UncompleteTodo.new(todo_id) },
        ->(todo_id) { ClearTodo.new(todo_id) }
      ]
    end
  end
end
