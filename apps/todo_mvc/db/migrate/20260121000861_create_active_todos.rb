class CreateActiveTodos < ActiveRecord::Migration[8.0]
  def change
    create_table :active_todos do |t|
      t.uuid :uid, null: false
      t.string :description
      t.timestamps
    end
    add_index :active_todos, :uid, unique: true
  end
end
