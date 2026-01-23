class CreateAllTodos < ActiveRecord::Migration[8.0]
  def change
    create_table :all_todos do |t|
      t.uuid :uid, null: false
      t.string :description
      t.boolean :completed, default: false, null: false
      t.timestamps
    end
    add_index :all_todos, :uid, unique: true
  end
end
