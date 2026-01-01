class AddOrderNumberToShipments < ActiveRecord::Migration[8.0]
  def change
    add_column :shipments, :order_number, :string
  end
end
