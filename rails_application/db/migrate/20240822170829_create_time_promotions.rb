class CreateTimePromotions < ActiveRecord::Migration[7.0]
  def change
    create_table :time_promotions do |t|
      t.datetime :start_time
      t.datetime :end_time
      t.string :label
      t.decimal :discount, precision: 5, scale: 2

      t.timestamps
    end
  end
end
