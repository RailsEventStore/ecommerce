class DropActiveTodosAndCompletedTodos < ActiveRecord::Migration[8.0]
  def change
    drop_table :active_todos
    drop_table :completed_todos
  end
end
