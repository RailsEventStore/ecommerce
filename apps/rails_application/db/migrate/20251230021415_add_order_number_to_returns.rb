class AddOrderNumberToReturns < ActiveRecord::Migration[8.0]
  def change
    add_column :returns, :order_number, :string
  end
end
