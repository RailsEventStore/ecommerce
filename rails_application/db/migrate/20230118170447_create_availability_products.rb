class CreateAvailabilityProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :availability_products do |t|
      t.uuid :uid
      t.boolean :available, default: true
    end
  end
end
