class CreateEntityNames < ActiveRecord::Migration[8.0]
  def change
    create_table :entity_names do |t|
      t.string :entity_type, null: false
      t.uuid :entity_uid, null: false
      t.string :name, null: false
    end

    add_index :entity_names, [:entity_type, :entity_uid], unique: true
  end
end
