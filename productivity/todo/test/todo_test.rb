require_relative "test_helper"

module Todo
  class TaskCreationTest < Test
    cover "Todo::Task"

    def test_add_task_twice_fails
      task_id = SecureRandom.uuid
      command_bus.call(AddTask.new(task_id: task_id))
      assert_raises TaskAlreadyExists do
        command_bus.call(AddTask.new(task_id: task_id))
      end
    end
  end
end