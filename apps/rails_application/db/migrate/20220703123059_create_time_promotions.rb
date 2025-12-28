class CreateTimePromotions < ActiveRecord::Migration[7.0]
  def change
    create_table :time_promotions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :label
      t.string :code
      t.integer :discount
      t.datetime :start_time
      t.datetime :end_time

      t.timestamps
    end
  end
end
