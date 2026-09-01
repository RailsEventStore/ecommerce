class CreatePolicies < ActiveRecord::Migration[8.1]
  def change
    create_table :policies do |t|
      t.uuid :policy_id
      t.decimal :premium
      t.string :state

      t.timestamps
    end
  end
end
