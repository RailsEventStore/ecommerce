class CreateHappyHours < ActiveRecord::Migration[7.0]
  def change
    create_table :happy_hours, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name
      t.string :code
      t.integer :discount
      t.integer :start_hour
      t.integer :end_hour
      t.string :product_ids, array: true

      t.timestamps
    end
  end
end
