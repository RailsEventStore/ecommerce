module Todo
  class AddTask < Infra::Command
    attribute :task_id, Infra::Types::UUID
  end

  class TaskAdded < Infra::Event
    attribute :task_id, Infra::Types::UUID
  end

  class TaskAlreadyExists < StandardError; end

  class AddTaskHandler
    def initialize(event_store)
      @event_store = event_store
    end

    def call(command)
      raise TaskAlreadyExists if task_stream_not_empty?(command)
      event_store.publish(TaskAdded.new(data: { task_id: command.task_id }), stream_name: "Task$#{command.task_id}")
    end

    private

    def task_stream_not_empty?(command)
      task_stream(command).to_a.size > 0
    end

    def task_stream(command)
      event_store.read.stream("Task$#{command.task_id}")
    end

    attr_reader :event_store
  end

end