class TodosController < ApplicationController
  def index
    @todos = case params[:filter]
    when "active"
      AllTodos.active
    when "completed"
      AllTodos.completed
    else
      AllTodos.all
    end
    @active_count = AllTodos.active_count
    @has_completed = AllTodos.completed_any?
    @has_todos = AllTodos.count > 0
    @filter = params[:filter] || "all"
  end

  def create
    todo_id = SecureRandom.uuid
    description = params[:description]

    ActiveRecord::Base.transaction do
      command_bus.call(Todo::AddTodo.new(todo_id: todo_id))
      if description.present?
        command_bus.call(Todo::SetTodoDescription.new(todo_id: todo_id, description: description))
      end
    end

    redirect_to root_path
  end

  def update
    command_bus.call(
      Todo::UpdateTodoDescription.new(todo_id: params[:id], description: params[:description])
    )
    redirect_to root_path
  end

  def complete
    command_bus.call(Todo::CompleteTodo.new(todo_id: params[:id]))
    redirect_to root_path
  end

  def uncomplete
    command_bus.call(Todo::UncompleteTodo.new(todo_id: params[:id]))
    redirect_to root_path
  end

  def destroy
    command_bus.call(Todo::ClearTodo.new(todo_id: params[:id]))
    redirect_to root_path
  end

  def clear_completed
    ActiveRecord::Base.transaction do
      AllTodos.completed.each do |todo|
        command_bus.call(Todo::ClearTodo.new(todo_id: todo.uid))
      end
    end
    redirect_to root_path
  end
end
