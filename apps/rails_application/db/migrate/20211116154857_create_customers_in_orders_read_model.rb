class CreateCustomersInOrdersReadModel < ActiveRecord::Migration[6.1]
  def change
    create_table :orders_customers do |t|
      t.uuid    "uid", null: false
      t.string  "name"
    end
  end
end
