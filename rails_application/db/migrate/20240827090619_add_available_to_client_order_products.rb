class AddAvailableToClientOrderProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :client_order_products, :available, :integer
  end
end
