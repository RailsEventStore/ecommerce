class AddClientColumnToOrder < ActiveRecord::Migration[7.0]
  def change
    add_column :client_orders, :client_name, :string
  end
end
