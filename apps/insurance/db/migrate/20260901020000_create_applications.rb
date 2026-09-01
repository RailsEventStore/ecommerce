class CreateApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :applications do |t|
      t.uuid :application_id
      t.decimal :coverage_amount
      t.string :risk_class
      t.decimal :premium
      t.string :state

      t.timestamps
    end
  end
end
