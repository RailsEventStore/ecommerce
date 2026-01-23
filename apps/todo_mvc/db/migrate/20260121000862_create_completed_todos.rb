class CreateCompletedTodos < ActiveRecord::Migration[8.0]
  def change
    create_table :completed_todos do |t|
      t.uuid :uid, null: false
      t.string :description
      t.timestamps
    end
    add_index :completed_todos, :uid, unique: true
  end
end
