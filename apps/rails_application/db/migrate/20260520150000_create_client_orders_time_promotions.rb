class CreateClientOrdersTimePromotions < ActiveRecord::Migration[8.0]
  def change
    create_table :client_orders_time_promotions, id: :uuid do |t|
      t.integer :discount
      t.datetime :start_time
      t.datetime :end_time
      t.string :label
      t.uuid :store_id
    end
  end
end
