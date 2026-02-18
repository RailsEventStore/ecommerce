class CreatePipelineStages < ActiveRecord::Migration[8.0]
  def change
    create_table :pipeline_stages do |t|
      t.uuid :pipeline_uid, null: false
      t.string :stage_name, null: false

      t.timestamps
    end
    add_index :pipeline_stages, [:pipeline_uid, :stage_name], unique: true
  end
end
