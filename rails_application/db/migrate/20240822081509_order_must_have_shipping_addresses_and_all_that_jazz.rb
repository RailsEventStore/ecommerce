class OrderMustHaveShippingAddressesAndAllThatJazz < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :country, :string
    add_column :orders, :city, :string
    add_column :orders, :street, :string
    add_column :orders, :zip, :string
    add_column :orders, :addressed_to, :string
  end
end
