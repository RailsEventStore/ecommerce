class CreateClientOrders < ActiveRecord::Migration[6.1]
  def change
    create_table :client_orders do |t|
      t.uuid :client_uid
      t.string :number
      t.uuid :order_uid
      t.string :state

      t.timestamps
    end
  end
end
