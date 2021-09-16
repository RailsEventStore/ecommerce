class CustomersAddRegisteredAt < ActiveRecord::Migration[6.1]
  def change
    add_column :customers, :registered_at, :datetime
  end
end
