class CreatePipelines < ActiveRecord::Migration[8.0]
  def change
    create_table :pipelines do |t|
      t.uuid :uid, null: false
      t.string :name, null: false

      t.timestamps
    end
    add_index :pipelines, :uid, unique: true
  end
end
