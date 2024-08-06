class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|

      t.string :first_name
      t.string :last_name
      t.string :email
      t.decimal :paid_orders_summary, precision: 8, scale: 2, default: "0.0"

      t.timestamps
    end
  end
end
