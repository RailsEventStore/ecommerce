class AddMaxUsesToCoupons < ActiveRecord::Migration[7.2]
  def change
    add_column :coupons, :max_uses, :integer
  end
end
